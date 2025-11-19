import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/models/category_chip_model.dart';
import '../../data/models/medal_model.dart';

class VolunteerModel extends BaseProfileModel {
  final String? fullName;
  final String? displayName;
  final String? frame;
  final int? currentLevel;
  final int? points;
  final int? achievementsCount;
  final int? seasonPoints; // Бали за поточний сезон
  final List<MedalModel>? medals;
  final String? currentGroupId;
  final String? currentSeasonId;

  VolunteerModel({
    // Поля базового класу
    super.uid,
    super.email,
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
    this.displayName,
    this.frame,
    this.currentLevel,
    this.points,
    this.achievementsCount,
    this.seasonPoints,
    this.medals,
    this.currentGroupId,
    this.currentSeasonId,
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
      'lastSignInAt': lastSignInAt != null
          ? Timestamp.fromDate(lastSignInAt!)
          : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'city': city,
      'aboutMe': aboutMe,
      'projectsCount': projectsCount,
      'eventsCount': eventsCount,
      'categoryChips': categoryChips?.map((e) => e.toMap()).toList(),
      'phoneNumber': phoneNumber,
      'telegramLink': telegramLink,
      'instagramLink': instagramLink,
      // Поля VolunteerModel
      'fullName': fullName,
      'frame': frame,
      'currentLevel': currentLevel,
      'points': points,
      'achievementsCount': achievementsCount,
      'seasonPoints': seasonPoints,
      'medals': medals?.map((e) => e.toMap()).toList(),
      'currentGroupId': currentGroupId,
      'currentSeasonId': currentSeasonId,
    };
  }

  factory VolunteerModel.fromMap(Map<String, dynamic> map) {
    DateTime? timestampToDateTime(dynamic ts) {
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
      lastSignInAt: timestampToDateTime(map['lastSignInAt']),
      createdAt: timestampToDateTime(map['createdAt']),
      city: map['city'] as String?,
      aboutMe: map['aboutMe'] as String?,
      projectsCount: map['projectsCount'] as int?,
      eventsCount: map['eventsCount'] as int?,
      fullName: map['fullName'] as String?,
      frame: map['frame'] as String?,
      currentLevel: map['currentLevel'] as int?,
      points: map['points'] as int?,
      achievementsCount: map['achievementsCount'] as int?,
      medals: (map['medals'] as List<dynamic>?)
          ?.map((e) => MedalModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      categoryChips: (map['categoryChips'] as List<dynamic>?)
          ?.map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      phoneNumber: map['phoneNumber'] as String?,
      telegramLink: map['telegramLink'] as String?,
      instagramLink: map['instagramLink'] as String?,
      seasonPoints: map['seasonPoints'] as int?,
      currentGroupId: map['currentGroupId'] as String?,
      currentSeasonId: map['currentSeasonId'] as String?,
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
    int? currentLevel,
    int? points,
    int? achievementsCount,
    List<MedalModel>? medals,
    List<CategoryChipModel>? categoryChips,
    String? phoneNumber,
    String? telegramLink,
    String? instagramLink,
    int? seasonPoints,
    String? currentGroupId,
    String? currentSeasonId
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
      currentLevel: currentLevel ?? this.currentLevel,
      points: points ?? this.points,
      achievementsCount: achievementsCount ?? this.achievementsCount,
      medals: medals ?? this.medals,
      categoryChips: categoryChips ?? this.categoryChips,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegramLink: telegramLink ?? this.telegramLink,
      instagramLink: instagramLink ?? this.instagramLink,
      seasonPoints: seasonPoints ?? this.seasonPoints,
      currentGroupId: currentGroupId ?? this.currentGroupId,
      currentSeasonId: currentSeasonId ?? this.currentSeasonId,
    );
  }
}
