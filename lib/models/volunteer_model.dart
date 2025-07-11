import 'package:cloud_firestore/cloud_firestore.dart';

import 'achievement_item_model.dart';
import 'base_profile_model.dart';
import 'category_chip_model.dart';
import 'medal_item_model.dart';

class VolunteerModel extends BaseProfileModel {
  final String? fullName;
  final String? frame;
  final String? levelTitle;
  final int? levelProgress;
  final String? levelDescription;
  final double? progressPercent;
  final int? pointsToNextLevel;
  final int? achievementsCount;
  final List<AchievementItemModel>? achievements;
  final List<MedalItemModel>? medals;
  final int? friendsCount;

  VolunteerModel({
    // Поля базового класу
    super.uid,
    super.email,
    super.displayName,
    super.photoUrl,
    super.lastSignInAt,
    super.createdAt,
    super.city,
    super.aboutMe,
    super.projectsCount,
    super.eventsCount,
    super.categoryChips,
    super.phoneNumber,
    super.telegramLink,
    super.instagramLink,
    // Поля VolunteerModel
    this.fullName,
    this.frame,
    this.levelTitle,
    this.levelProgress,
    this.levelDescription,
    this.progressPercent,
    this.pointsToNextLevel,
    this.achievementsCount,
    this.achievements,
    this.medals,
    this.friendsCount,

  }) : super(role: UserRole.volunteer); // Встановлюємо роль для волонтера

  @override
  Map<String, dynamic> toMap() {
    return {
      // Поля базового класу
      'uid': uid,
      'email': email,
      'role': role?.name,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastSignInAt': lastSignInAt != null ? Timestamp.fromDate(lastSignInAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'city': city,
      'aboutMe': aboutMe,
      'projectsCount': projectsCount,
      'eventsCount': eventsCount,
      'categoryChips': categoryChips?.map((e) => e.toMap()).toList(),
      'phoneNumber':phoneNumber,
      'telegramLink':telegramLink,
      'instagramLink':instagramLink,
      // Поля VolunteerModel
      'fullName': fullName,
      'frame': frame,
      'levelTitle': levelTitle,
      'levelProgress': levelProgress,
      'levelDescription': levelDescription,
      'progressPercent': progressPercent,
      'pointsToNextLevel': pointsToNextLevel,
      'achievementsCount': achievementsCount,
      'achievements': achievements?.map((e) => e.toMap()).toList(),
      'medals': medals?.map((e) => e.toMap()).toList(),
      'friendsCount': friendsCount,
    };
  }

  factory VolunteerModel.fromMap(Map<String, dynamic> map) {
    // Helper function to parse DateTime from Timestamp
    DateTime? _timestampToDateTime(dynamic ts) {
      if (ts is Timestamp) {
        return ts.toDate();
      } else if (ts is String) {
        return DateTime.tryParse(ts);
      }
      return null;
    }

    return VolunteerModel(
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      lastSignInAt: _timestampToDateTime(map['lastSignInAt']),
      createdAt: _timestampToDateTime(map['createdAt']),
      city: map['city'] as String?,
      aboutMe: map['aboutMe'] as String?,
      projectsCount: map['projectsCount'] as int?,
      eventsCount: map['eventsCount'] as int?,
      fullName: map['fullName'] as String?,
      frame: map['frame'] as String?,
      levelTitle: map['levelTitle'] as String?,
      levelProgress: map['levelProgress'] as int?,
      levelDescription: map['levelDescription'] as String?,
      progressPercent: map['progressPercent'] as double?,
      pointsToNextLevel: map['pointsToNextLevel'] as int?,
      achievementsCount: map['achievementsCount'] as int?,
      achievements: (map['achievements'] as List<dynamic>?)
          ?.map((e) => AchievementItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      medals: (map['medals'] as List<dynamic>?)
          ?.map((e) => MedalItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      friendsCount: map['friendsCount'] as int?,
      categoryChips: (map['categoryChips'] as List<dynamic>?)
          ?.map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      phoneNumber: map['phoneNumber'] as String?,
      telegramLink: map['telegramLink'] as String?,
      instagramLink: map['instagramLink'] as String?,
    );
  }

  VolunteerModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? lastSignInAt,
    DateTime? createdAt,
    String? city,
    String? aboutMe,
    int? projectsCount,
    int? eventsCount,
    String? fullName,
    String? frame,
    String? levelTitle,
    int? levelProgress,
    String? levelDescription,
    double? progressPercent,
    int? pointsToNextLevel,
    int? achievementsCount,
    List<AchievementItemModel>? achievements,
    List<MedalItemModel>? medals,
    int? friendsCount,
    List<CategoryChipModel>? categoryChips,
    String? phoneNumber,
    String? telegramLink,
    String? instagramLink,
  }) {
    return VolunteerModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      aboutMe: aboutMe ?? this.aboutMe,
      projectsCount: projectsCount ?? this.projectsCount,
      eventsCount: eventsCount ?? this.eventsCount,
      fullName: fullName ?? this.fullName,
      frame: frame ?? this.frame,
      levelTitle: levelTitle ?? this.levelTitle,
      levelProgress: levelProgress ?? this.levelProgress,
      levelDescription: levelDescription ?? this.levelDescription,
      progressPercent: progressPercent ?? this.progressPercent,
      pointsToNextLevel: pointsToNextLevel ?? this.pointsToNextLevel,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      achievements: achievements ?? this.achievements,
      medals: medals ?? this.medals,
      friendsCount: friendsCount ?? this.friendsCount,
      categoryChips: categoryChips ?? this.categoryChips,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegramLink: telegramLink ?? this.telegramLink,
      instagramLink: instagramLink ?? this.instagramLink,
    );
  }
}
