import 'package:cloud_firestore/cloud_firestore.dart';
import 'base_profile_model.dart';

class AdminModel extends BaseProfileModel {
  final String? fullName;
  final List<String>? permissions;

  AdminModel({
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
    this.fullName,
    this.permissions,
  }) : super(role: UserRole.admin);

  @override
  Map<String, dynamic> toMap() {
    return {
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
      'fullName': fullName,
      'permissions': permissions,
    };
  }

  factory AdminModel.fromMap(Map<String, dynamic> map) {
    DateTime? timestampToDateTime(dynamic ts) {
      if (ts is Timestamp) {
        return ts.toDate();
      } else if (ts is String) {
        return DateTime.tryParse(ts);
      }
      return null;
    }

    return AdminModel(
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      photoUrl: map['photoUrl'] as String?,
      lastSignInAt: timestampToDateTime(map['lastSignInAt']),
      createdAt: timestampToDateTime(map['createdAt']),
      city: map['city'] as String?,
      aboutMe: map['aboutMe'] as String?,
      projectsCount: map['projectsCount'] as int?,
      eventsCount: map['eventsCount'] as int?,
      fullName: map['fullName'] as String?,
      permissions: (map['permissions'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      phoneNumber: map['phoneNumber'] as String?,
      telegramLink: map['telegramLink'] as String?,
      instagramLink: map['instagramLink'] as String?,
    );
  }

  AdminModel copyWith({
    String? uid,
    String? email,
    String? photoUrl,
    DateTime? lastSignInAt,
    DateTime? createdAt,
    String? city,
    String? aboutMe,
    int? projectsCount,
    int? eventsCount,
    String? fullName,
    List<String>? permissions,
    DateTime? lastActivityAt,
    String? phoneNumber,
    String? telegramLink,
    String? instagramLink,
  }) {
    return AdminModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      aboutMe: aboutMe ?? this.aboutMe,
      projectsCount: projectsCount ?? this.projectsCount,
      eventsCount: eventsCount ?? this.eventsCount,
      fullName: fullName ?? this.fullName,
      permissions: permissions ?? this.permissions,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegramLink: telegramLink ?? this.telegramLink,
      instagramLink: instagramLink ?? this.instagramLink,
    );
  }
}
