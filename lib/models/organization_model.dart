import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/trust_badge_model.dart';

import 'base_profile_model.dart';
import 'category_chip_model.dart';

class OrganizationModel extends BaseProfileModel {
  final String? organizationName;
  final String? website;
  final List<String>? documents;
  final bool? isVerification;
  final int? fundraisingsCount;
  final List<TrustBadgeModel>? trustBadges;

  OrganizationModel({
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
    // Поля OrganizationModel
    this.organizationName,
    this.website,
    this.documents,
    this.isVerification,
    this.fundraisingsCount,
    this.trustBadges,
  }) : super(role: UserRole.organization);

  @override
  Map<String, dynamic> toMap() {
    return {
      // Поля базового класу
      'uid': uid,
      'email': email,
      'role': role?.name,
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
      // Поля OrganizationModel
      'organizationName': organizationName,
      'website': website,
      'documents': documents,
      'isVerification': isVerification,
      'fundraisingsCount': fundraisingsCount,
      'trustBadges': trustBadges?.map((e) => e.toMap()).toList(),
    };
  }

  factory OrganizationModel.fromMap(Map<String, dynamic> map) {
    DateTime? _timestampToDateTime(dynamic ts) {
      if (ts is Timestamp) {
        return ts.toDate();
      } else if (ts is String) {
        return DateTime.tryParse(ts);
      }
      return null;
    }

    return OrganizationModel(
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      lastSignInAt: _timestampToDateTime(map['lastSignInAt']),
      createdAt: _timestampToDateTime(map['createdAt']),
      city: map['city'] as String?,
      aboutMe: map['aboutMe'] as String?,
      projectsCount: map['projectsCount'] as int?,
      eventsCount: map['eventsCount'] as int?,
      organizationName: map['organizationName'] as String?,
      website: map['website'] as String?,
      documents: (map['documents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isVerification: map['isVerification'] as bool?,
      fundraisingsCount: map['fundraisingsCount'] as int?,
      trustBadges: (map['trustBadges'] as List<dynamic>?)
          ?.map((e) => TrustBadgeModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      categoryChips: (map['categoryChips'] as List<dynamic>?)
          ?.map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      phoneNumber: map['phoneNumber'] as String?,
      telegramLink: map['telegramLink'] as String?,
      instagramLink: map['instagramLink'] as String?,
    );
  }

  OrganizationModel copyWith({
    String? uid,
    String? email,
    String? photoUrl,
    DateTime? lastSignInAt,
    DateTime? createdAt,
    String? city,
    String? aboutMe,
    int? projectsCount,
    int? eventsCount,
    String? organizationName,
    String? website,
    List<String>? documents,
    bool? isVerification,
    int? feesCount,
    List<TrustBadgeModel>? trustBadges,
    List<CategoryChipModel>? categoryChips,
    String? phoneNumber,
    String? telegramLink,
    String? instagramLink,
  }) {
    return OrganizationModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      aboutMe: aboutMe ?? this.aboutMe,
      projectsCount: projectsCount ?? this.projectsCount,
      eventsCount: eventsCount ?? this.eventsCount,
      organizationName: organizationName ?? this.organizationName,
      website: website ?? this.website,
      documents: documents ?? this.documents,
      isVerification: isVerification ?? this.isVerification,
      fundraisingsCount: feesCount ?? this.fundraisingsCount,
      trustBadges: trustBadges ?? this.trustBadges,
      categoryChips: categoryChips ?? this.categoryChips,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegramLink: telegramLink ?? this.telegramLink,
      instagramLink: instagramLink ?? this.instagramLink,
    );
  }
}
