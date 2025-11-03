import 'package:cloud_firestore/cloud_firestore.dart';

class UserAchievementModel {
  final String achievementId;
  final DateTime unlockedAt;
  final bool dialogShown;

  UserAchievementModel({
    required this.achievementId,
    required this.unlockedAt,
    this.dialogShown = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'achievementId': achievementId,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'dialogShown': dialogShown,
    };
  }

  factory UserAchievementModel.fromMap(Map<String, dynamic> map) {
    return UserAchievementModel(
      achievementId: map['achievementId'] as String,
      unlockedAt: (map['unlockedAt'] as Timestamp).toDate(),
      dialogShown: map['dialogShown'] as bool? ?? false,
    );
  }

  UserAchievementModel copyWith({
    String? achievementId,
    DateTime? unlockedAt,
    bool? dialogShown,
  }) {
    return UserAchievementModel(
      achievementId: achievementId ?? this.achievementId,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      dialogShown: dialogShown ?? this.dialogShown,
    );
  }
}