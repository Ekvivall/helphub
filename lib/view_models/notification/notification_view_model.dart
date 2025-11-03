import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/services/achievement_service.dart';
import 'package:helphub/data/services/notification_service.dart';
import 'package:helphub/data/models/notification_model.dart';

import '../../core/utils/constants.dart';
import '../../data/models/user_achievement_model.dart';
import '../../widgets/achievement/achievement_notification_dialog.dart';

class NotificationViewModel with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot>? _achievementsSubscription;
  AchievementService _achievementService = AchievementService();

  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<NotificationModel>>? _notificationsSubscription;
  StreamSubscription<int>? _unreadCountSubscription;
  StreamSubscription<DocumentSnapshot>? _userSettingsSubscription;

  bool get isAllNotificationsEnabled =>
      _notificationSettings.values.any((enabled) => enabled);

  List<NotificationModel> get notifications => _notifications;

  int get unreadCount => _unreadCount;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<NotificationModel> get unreadNotifications =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get readNotifications =>
      _notifications.where((n) => n.isRead).toList();

  List<NotificationModel> getNotificationsByType(NotificationType type) =>
      _notifications.where((n) => n.type == type).toList();

  // Налаштування сповіщень
  Map<NotificationType, bool> _notificationSettings = {};
  bool _settingsLoaded = false;

  Map<NotificationType, bool> get notificationSettings => _notificationSettings;

  bool get settingsLoaded => _settingsLoaded;

  Future<void> initialize(BuildContext context) async {
    await _notificationService.initialize(context);
    _startListeningToSettings();
    _startListening();
    _startListeningForAchievements();
  }
  void _startListeningForAchievements() {
    _achievementsSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _achievementsSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .snapshots()
        .listen((snapshot) {
      final context = NotificationService.navigatorKey?.currentContext;
      if (context == null) return;

      for (final doc in snapshot.docs) {
        final achievementData = UserAchievementModel.fromMap(doc.data());
        if (!achievementData.dialogShown) {
          final achievement = Constants.allAchievements.firstWhere(
                (a) => a.id == achievementData.achievementId,
          );

          if (achievement.id.isNotEmpty) {
            AchievementNotificationDialog.show(context, achievement);
            _achievementService.markAchievementDialogAsShown(user.uid, achievement.id);
          }
        }
      }
    });
  }
  void _startListeningToSettings() {
    _userSettingsSubscription?.cancel();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _setDefaultSettings();
      return;
    }

    _userSettingsSubscription = _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen(
          (userDoc) {
            if (userDoc.exists &&
                userDoc.data()!.containsKey('notificationSettings')) {
              final settings =
                  userDoc.data()!['notificationSettings']
                      as Map<String, dynamic>;

              final newSettings = <NotificationType, bool>{};
              for (final type in NotificationType.values) {
                newSettings[type] = settings[type.name] ?? true;
              }
              _notificationSettings = newSettings;
            }
            _settingsLoaded = true;
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to notification settings: $error');
            _setDefaultSettings();
          },
        );
  }

  Future<void> updateNotificationSetting(
    NotificationType type,
    bool enabled,
  ) async {
    // Локальне оновлення для миттєвої реакції UI
    _notificationSettings[type] = enabled;
    notifyListeners();

    await _saveNotificationSettings();

    if (!enabled) {
      await _markTypeNotificationsAsRead(type);
    }
  }

  void updateCategorySetting(NotificationCategory category, bool isEnabled) {
    final typesToUpdate = Constants.notificationGroups[category]!;
    for (final type in typesToUpdate) {
      updateNotificationSetting(type, isEnabled);
    }
  }

  void _setDefaultSettings() {
    _notificationSettings = {};
    for (final type in NotificationType.values) {
      _notificationSettings[type] = true;
    }
    _settingsLoaded = true;
    notifyListeners();
  }

  Future<void> _saveNotificationSettings() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final settingsMap = <String, bool>{};
      for (final entry in _notificationSettings.entries) {
        settingsMap[entry.key.name] = entry.value;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'notificationSettings': settingsMap,
        'notificationSettingsUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving notification settings: $e');
    }
  }

  Future<void> _markTypeNotificationsAsRead(NotificationType type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final batch = _firestore.batch();
      final typeNotifications = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('notifications')
          .where('type', isEqualTo: type.name)
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in typeNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking type notifications as read: $e');
    }
  }

  bool isNotificationTypeEnabled(NotificationType type) {
    return _notificationSettings[type] ?? true;
  }

  Map<String, dynamic> getNotificationStatistics() {
    final enabledCount = _notificationSettings.values
        .where((enabled) => enabled)
        .length;
    final totalCount = _notificationSettings.length;

    return {
      'enabled': enabledCount,
      'total': totalCount,
      'percentage': totalCount > 0
          ? (enabledCount / totalCount * 100).round()
          : 0,
    };
  }

  Future<void> updateMultipleSettings(
    Map<NotificationType, bool> settings,
  ) async {
    for (final entry in settings.entries) {
      _notificationSettings[entry.key] = entry.value;
    }
    notifyListeners();
    await _saveNotificationSettings();
  }

  Future<void> resetToDefaultSettings() async {
    _setDefaultSettings();
    await _saveNotificationSettings();
  }

  void _startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _setLoading(true);

    _notificationsSubscription = _notificationService
        .getUserNotifications()
        .listen(
          (notifications) {
            _notifications = _filterNotificationsBySettings(notifications);
            _setLoading(false);
            _clearError();
            notifyListeners();
          },
          onError: (error) {
            _setError('Помилка завантаження сповіщень: $error');
            _setLoading(false);
          },
        );

    _unreadCountSubscription = _notificationService
        .getUnreadNotificationsCount()
        .listen(
          (count) {
            _calculateFilteredUnreadCount();
            notifyListeners();
          },
          onError: (error) {
            print('Error listening to unread count: $error');
          },
        );
  }

  List<NotificationModel> _filterNotificationsBySettings(
    List<NotificationModel> notifications,
  ) {
    if (!_settingsLoaded) return notifications;

    return notifications.where((notification) {
      return isNotificationTypeEnabled(notification.type);
    }).toList();
  }

  void _calculateFilteredUnreadCount() {
    if (!_settingsLoaded) return;

    _unreadCount = _notifications.where((notification) {
      return !notification.isRead &&
          isNotificationTypeEnabled(notification.type);
    }).length;
  }

  void stopListening() {
    _notificationsSubscription?.cancel();
    _unreadCountSubscription?.cancel();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markNotificationAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _calculateFilteredUnreadCount();
        notifyListeners();
      }
    } catch (e) {
      _setError('Помилка оновлення сповіщення: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _setLoading(true);
      await _notificationService.markAllNotificationsAsRead();

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Помилка позначення всіх сповіщень: $e');
      _setLoading(false);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      _calculateFilteredUnreadCount();
      notifyListeners();
    } catch (e) {
      _setError('Помилка видалення сповіщення: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      _setLoading(true);
      await _notificationService.clearAllNotifications();
      _notifications.clear();
      _unreadCount = 0;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError('Помилка очищення сповіщень: $e');
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _startListeningToSettings();
    _startListening();
  }

  List<NotificationModel> getNotificationsFromLastDays(int days) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _notifications
        .where((n) => n.timestamp.isAfter(cutoffDate))
        .toList();
  }

  Map<String, List<NotificationModel>> getNotificationsGroupedByDate() {
    final Map<String, List<NotificationModel>> grouped = {};
    for (final notification in _notifications) {
      final date = _formattedDateForGrouping(notification.timestamp);
      if (grouped[date] == null) {
        grouped[date] = [];
      }
      grouped[date]!.add(notification);
    }
    return grouped;
  }

  String _formattedDateForGrouping(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Сьогодні';
    } else if (notificationDate == yesterday) {
      return 'Вчора';
    } else if (now.difference(date).inDays < 7) {
      const weekdays = [
        'Понеділок',
        'Вівторок',
        'Середа',
        'Четвер',
        'П\'ятниця',
        'Субота',
        'Неділя',
      ];
      return weekdays[date.weekday - 1];
    } else {
      return '${date.day}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }

  Map<NotificationType, int> getNotificationStatisticsByType() {
    final Map<NotificationType, int> stats = {};
    for (final type in NotificationType.values) {
      stats[type] = _notifications.where((n) => n.type == type).length;
    }
    return stats;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void handleNotificationTap(
    NotificationModel notification,
    BuildContext context,
  ) {
    if (!isNotificationTypeEnabled(notification.type)) {
      return;
    }

    if (!notification.isRead) {
      markAsRead(notification.id);
    }

    _notificationService.navigateFromNotificationData(
      notification.data,
      notification.type,
    );
  }

  void toggleAllNotifications() async {
    final newState = !isAllNotificationsEnabled;
    for (final type in NotificationType.values) {
      _notificationSettings[type] = newState;
    }
    await _saveNotificationSettings();

    if (!newState) {
      await markAllAsRead();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    _userSettingsSubscription?.cancel();
    super.dispose();
  }
}
