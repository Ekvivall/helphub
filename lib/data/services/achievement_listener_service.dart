import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/data/models/achievement_item_model.dart';

import '../../main.dart';
import '../../widgets/achievement/achievement_notification_dialog.dart';

class AchievementListenerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _achievementsSubscription;
  Set<String> _processedAchievementIds = {};

  void initialize() {
    _startListening();
  }

  void _startListening() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    stopListening();
    _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get()
        .then((snapshot) {
      _processedAchievementIds = snapshot.docs
          .map((doc) => doc.id)
          .toSet();

      _achievementsSubscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .snapshots()
          .listen(_onAchievementsChanged);
    });
  }
  void stopListening() {
    _achievementsSubscription?.cancel();
    _achievementsSubscription = null;
    _processedAchievementIds.clear();
  }

  void _onAchievementsChanged(QuerySnapshot snapshot) {
    for (var change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added) {
        final achievementId = change.doc.id;

        // Якщо це нове досягнення
        if (!_processedAchievementIds.contains(achievementId)) {
          _processedAchievementIds.add(achievementId);
          _showAchievementNotification(achievementId);
        }
      }
    }
  }

  void _showAchievementNotification(String achievementId) {
    final navigatorContext = HelpHubApp.navigatorKey.currentContext;

    if (navigatorContext == null) {
      print("Cannot show achievement dialog: Navigator context is null.");
      return;
    }
    final achievement = Constants.allAchievements
        .firstWhere(
          (a) => a.id == achievementId,
      orElse: () => AchievementModel(
        id: achievementId,
        title: 'Нове досягнення',
        description: 'Вітаємо!',
        iconPath: ImageConstant.imgImageNotFound,
        isSecret: false,
        order: 99,
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (HelpHubApp.navigatorKey.currentState?.mounted == true) {
        AchievementNotificationDialog.show(navigatorContext, achievement);
      }
    });
  }

  void dispose() {
    stopListening();
  }

}
