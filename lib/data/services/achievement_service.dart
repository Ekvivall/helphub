import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user_achievement_model.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<UserAchievementModel>> getUserAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserAchievementModel.fromMap(doc.data()))
              .toList();
        });
  }

  Future<void> markAchievementDialogAsShown(String userId, String achievementId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('achievements')
          .doc(achievementId)
          .update({'dialogShown': true});
    } catch (e) {
      print("Error updating dialogShown flag: $e");
    }
  }
}
