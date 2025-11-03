import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:helphub/data/services/project_service.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/views/chat/chat_project_screen.dart';

import '../../data/models/notification_model.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('Notification tapped in background: ${notificationResponse.payload}');
  NotificationService._pendingNotificationData = notificationResponse.payload;
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _fcmToken;
  bool _isAppInForeground = true;
  String? _currentChatId; // Для перевірки чи користувач в чаті
  final Set<String> _processedNotifications = <String>{};

  void setAppForegroundState(bool isInForeground) {
    _isAppInForeground = isInForeground;
  }

  void setCurrentChatId(String? chatId) {
    _currentChatId = chatId;
  }

  // Глобальний ключ для навігації
  static GlobalKey<NavigatorState>? navigatorKey;

  static String? _pendingNotificationData;
  static RemoteMessage? _pendingRemoteMessage;

  Future<void> initialize(BuildContext context) async {
    await _requestPermissions();
    await _initializeLocalNotifications();
    await _getFCMToken();
    _setupMessageHandlers();
    _handleInitialMessage();
    await _processPendingNotification();
  }

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    navigatorKey = key;
  }

  // Запитує дозвіл на push-нотифікації
  Future<void> _requestPermissions() async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_volunteer');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );
    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: _onLocalNotificationTapped,
    );
  }

  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      await _saveFCMToken();
      _messaging.onTokenRefresh.listen(_saveFCMToken);
    } catch (e) {
      print('Error getting FCM token: $e');
    }
  }

  Future<void> _saveFCMToken([String? token]) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final tokenToSave = token ?? _fcmToken;
        if (tokenToSave != null) {
          await _firestore.collection('users').doc(user.uid).update({
            'fcmToken': tokenToSave,
            'platform': Platform.isAndroid ? 'android' : 'ios',
            'lastTokenUpdate': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    // Повідомлення отримане коли додаток активний
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Повідомлення натиснуте коли додаток у фоні
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked from background: ${message.data}');
      _pendingRemoteMessage = message;
      Future.delayed(const Duration(milliseconds: 1000), () {
        _navigateBasedOnNotification(message);
      });
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final messageId =
        message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString();

    if (_processedNotifications.contains(messageId)) {
      print('Message already processed: $messageId');
      return;
    }

    _processedNotifications.add(messageId);

    if (_processedNotifications.length > 100) {
      final oldIds = _processedNotifications.take(
        _processedNotifications.length - 100,
      );
      _processedNotifications.removeAll(oldIds);
    }

    final notificationType = message.data['type'];
    if (notificationType != 'chat' &&
        notificationType != 'fundraisingDonation') {
      await _saveNotificationToFirestore(message);
    }

    await _showAppropriateNotification(message);
  }

  Future<void> _showAppropriateNotification(RemoteMessage message) async {
    final notificationType = message.data['type'];
    final chatId = message.data['chatId'];

    // Для чат-повідомлень
    if (notificationType == 'chat') {
      if (_currentChatId == chatId) {
        return;
      }
    }
    if (_isAppInForeground) {
      if (notificationType == 'achievement') {
        await _showLocalNotification(message);
        return;
      }
      _showInAppNotification(message);
    }
    await _showLocalNotification(message);
  }

  // Обробка початкового повідомлення (додаток закритий)
  Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      print('App opened from terminated state: ${initialMessage.data}');
      _pendingRemoteMessage = initialMessage;
      // Затримка для завантаження додатку
      Future.delayed(const Duration(milliseconds: 2000), () {
        _navigateBasedOnNotification(initialMessage);
      });
    }
  }

  // Обробка відкладених повідомлень
  Future<void> _processPendingNotification() async {
    if (_pendingNotificationData != null) {
      print('Processing pending notification data: $_pendingNotificationData');
      try {
        final data = jsonDecode(_pendingNotificationData!);
        final message = RemoteMessage(
          data: Map<String, String>.from(data),
          messageId: DateTime.now().millisecondsSinceEpoch.toString(),
        );
        await Future.delayed(const Duration(milliseconds: 1000));
        await _navigateBasedOnNotification(message);
        _pendingNotificationData = null;
      } catch (e) {
        print('Error processing pending notification: $e');
      }
    }

    if (_pendingRemoteMessage != null) {
      print(
        'Processing pending remote message: ${_pendingRemoteMessage!.data}',
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      await _navigateBasedOnNotification(_pendingRemoteMessage!);
      _pendingRemoteMessage = null;
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'helphub_channel',
          'HelpHub notifications',
          channelDescription: 'Notifications for chat HelpHub app',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      message.notification?.title ?? 'HelpHub',
      message.notification?.body ?? 'У вас нове повідомлення',
      details,
      payload: jsonEncode(message.data),
    );
  }

  void _showInAppNotification(RemoteMessage message) {
    final context = navigatorKey?.currentContext;
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: appThemeColors.backgroundLightGrey,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'Нове сповіщення',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              Text(
                message.notification?.body ?? '',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'Переглянути',
            textColor: appThemeColors.blueAccent,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              navigateFromNotificationData(message.data, null);
            },
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> navigateFromNotificationData(
    Map<String, dynamic> data,
    NotificationType? type) async {
    final navigator = navigatorKey?.currentState;
    if (navigator == null) {
      return;
    }
    if (type == null) {
      final typeString = data['type'] as String?;
      if (typeString == null) {
        navigator.pushNamed(AppRoutes.notificationsScreen);
        return;
      }

      try {
        type = NotificationType.values.firstWhere(
          (t) => t.name == typeString,
          orElse: () => NotificationType.general,
        );
      } catch (e) {
        print('Error parsing notification type: $typeString');
        navigator.pushNamed(AppRoutes.notificationsScreen);
        return;
      }
    }
    switch (type) {
      case NotificationType.chat:
        final chatId = data['chatId'];
        final chatType = data['chatType'];

        if (chatType == 'friend') {
          navigator.pushNamed(AppRoutes.chatFriendScreen, arguments: chatId);
        } else if (chatType == 'event') {
          navigator.pushNamed(AppRoutes.chatEventScreen, arguments: chatId);
        } else if (chatType == 'project') {
          navigator.pushNamed(
            AppRoutes.chatProjectScreen,
            arguments: {'chatId': chatId, 'displayMode': DisplayMode.chat},
          );
        }
        break;
      case NotificationType.fundraisingApplication:
        navigator.pushNamed(AppRoutes.allFundraiserApplicationsScreen);
        break;
      case NotificationType.fundraisingApplicationEdit:
      case NotificationType.projectApplicationEdit:
        navigator.pushNamed(AppRoutes.allApplicationsScreen);
        break;
      case NotificationType.fundraisingDonation:
        final fundraisingId = data['fundraisingId'];
        navigator.pushNamed(
          AppRoutes.fundraisingDonationsScreen,
          arguments: fundraisingId,
        );
        break;
      case NotificationType.reportCreated:
        final reportId = data['reportId'];
        navigator.pushNamed(
          AppRoutes.viewReportScreen,
          arguments: {'reportId': reportId, 'canLeaveFeedback': true},
        );
        break;
      case NotificationType.friendRequest:
        navigator.pushNamed(AppRoutes.friendRequestsScreen);
        break;
      case NotificationType.friendRequestEdit:
        navigator.pushNamed(AppRoutes.friendsListScreen);
        break;
      case NotificationType.taskAssigned:
      case NotificationType.taskCompleted:
      case NotificationType.taskConfirmed:
      case NotificationType.projectDeadline:
      case NotificationType.projectApplication:
        final projectId = data['projectId'];
        final projectHelper = ProjectService();
        String? chatId = await projectHelper.getProjectChatId(projectId);
        if (chatId != null) {
          navigator.pushNamed(
            AppRoutes.chatProjectScreen,
            arguments: {'chatId': chatId, 'displayMode': DisplayMode.tasks},
          );
        }
        break;
      case NotificationType.raffleWinner:
        final fundraisingId = data['fundraisingId'];
        navigator.pushNamed(
          AppRoutes.fundraisingDetailScreen,
          arguments: fundraisingId,
        );
        break;
      case NotificationType.eventUpdate:
        final eventId = data['eventId'];
        navigator.pushNamed(AppRoutes.eventDetailScreen, arguments: eventId);
        break;
      case NotificationType.eventReminder:
        navigator.pushNamed(AppRoutes.calendarScreen);
        break;
      case NotificationType.newFundraising:
      case NotificationType.fundraisingCompleted:
        final fundraisingId = data['fundraisingId'];
        navigator.pushNamed(
          AppRoutes.fundraisingDetailScreen,
          arguments: fundraisingId,
        );
        break;
      case NotificationType.achievement:
        navigator.pushNamed(AppRoutes.achievementsScreen);
        break;
      case NotificationType.adminNotification:
      case NotificationType.systemMaintenance:
      case NotificationType.appUpdate:
      case NotificationType.general:
        navigator.pushNamed(AppRoutes.notificationsScreen);
        break;
    }
  }

  Future<void> _navigateBasedOnNotification(RemoteMessage message) async {
    await navigateFromNotificationData(message.data, null);
  }

  void _onLocalNotificationTapped(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        final messageId =
            data['messageId'] ??
            DateTime.now().millisecondsSinceEpoch.toString();

        if (_processedNotifications.contains('tap_$messageId')) {
          print('Notification tap already processed: $messageId');
          return;
        }

        _processedNotifications.add('tap_$messageId');

        Future.delayed(const Duration(milliseconds: 500), () {
          navigateFromNotificationData(Map<String, dynamic>.from(data), null);
        });
      } catch (e) {
        print('Error parsing notification payload: $e');
        _navigateToNotifications();
      }
    }
  }

  void _navigateToNotifications() {
    if (navigatorKey?.currentState != null) {
      navigatorKey!.currentState!.pushNamed(AppRoutes.notificationsScreen);
    }
  }

  Future<void> processPendingNotifications() async {
    await _processPendingNotification();
  }

  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final notification = NotificationModel(
          id:
              message.messageId ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: message.notification?.title ?? '',
          body: message.notification?.body ?? '',
          type: NotificationType.values.firstWhere(
            (type) => type.name == message.data['type'],
            orElse: () => NotificationType.general,
          ),
          data: message.data as Map<String, String>,
          isRead: false,
          timestamp: DateTime.now(),
        );

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notification.id)
            .set(notification.toMap());
      }
    } catch (e) {
      print('Error saving notification to Firestore: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        final notifications = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .where('isRead', isEqualTo: false)
            .get();
        for (final doc in notifications.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  Stream<int> getUnreadNotificationsCount() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value(0);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<NotificationModel>> getUserNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> clearAllNotifications() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final batch = _firestore.batch();
        final notifications = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('notifications')
            .get();
        for (final doc in notifications.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error clearing all notifications: $e');
    }
  }

  String? get fcmToken => _fcmToken;
}
