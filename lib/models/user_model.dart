import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum UserRole { volunteer, organization }

class UserModel {
  final String? uid;
  final String? email;
  final UserRole? role;
  final String? displayName;
  final String? photoUrl;
  final DateTime? lastSignInAt;
  final DateTime? createdAt;
  final String? fullName;
  final String? organizationName;
  final String? website;
  final List<String>? documents;
  final bool? isVerification;
  final String? city;

  UserModel({
    this.uid,
    required this.email,
    this.role,
    this.displayName,
    this.photoUrl,
    this.lastSignInAt,
    this.createdAt,
    this.fullName,
    this.organizationName,
    this.website,
    this.documents,
    this.isVerification,
    this.city,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'role': role.toString().split('.').last,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'lastSignInAt': lastSignInAt != null
          ? Timestamp.fromDate(lastSignInAt!)
          : FieldValue.serverTimestamp(),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'fullName': fullName,
      'organizationName': organizationName,
      'website': website,
      'city': city,
      'documents': documents,
      'isVerification': isVerification,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] as String?,
      email: map['email'] as String?,
      role: _stringToUserRole(map['role'] as String?),
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
      lastSignInAt: (map['lastSignInAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      fullName: map['fullName'] as String?,
      organizationName: map['organizationName'] as String?,
      website: map['website'] as String?,
      city: map['city'] as String?,
      documents: (map['documents'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isVerification: map['isVerification'] as bool?,
    );
  }

  //Допоміжна функція для перетворення рядка на UserRole enum
  static UserRole? _stringToUserRole(String? roleString) {
    switch (roleString) {
      case 'volunteer':
        return UserRole.volunteer;
      case 'organization':
        return UserRole.organization;
      default:
        return null;
    }
  }

  // Метод для створення нової копії UserModel зі зміненими полями
  UserModel copyWith({
    String? uid,
    String? email,
    UserRole? role,
    String? displayName,
    String? photoUrl,
    DateTime? lastSignInAt,
    DateTime? createdAt,
    String? fullName,
    String? organizationName,
    String? website,
    List<String>? documents,
    bool? isVerification,
    String? city,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      lastSignInAt: lastSignInAt ?? this.lastSignInAt,
      createdAt: createdAt ?? this.createdAt,
      fullName: fullName ?? this.fullName,
      organizationName: organizationName ?? this.organizationName,
      website: website ?? this.website,
      documents: documents ?? this.documents,
      isVerification: isVerification ?? this.isVerification,
      city: city ?? this.city,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, role: ${role.toString().split('.').last}, displayName: $displayName, photoUrl: $photoUrl, lastSignInAt: $lastSignInAt, createdAt: $createdAt, fullName: $fullName, organizationName: $organizationName, website: $website, documents: $documents, isVerification: $isVerification, city: $city)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          uid == other.uid &&
          email == other.email &&
          role == other.role &&
          displayName == other.displayName &&
          photoUrl == other.photoUrl &&
          lastSignInAt == other.lastSignInAt &&
          createdAt == other.createdAt &&
          fullName == other.fullName &&
          organizationName == other.organizationName &&
          website == other.website &&
          listEquals(other.documents, documents) &&
          isVerification == other.isVerification &&
          city == other.city;

  @override
  int get hashCode => Object.hash(
    uid,
    email,
    role,
    displayName,
    photoUrl,
    lastSignInAt,
    createdAt,
    fullName,
    organizationName,
    website,
    documents,
    isVerification,
    city,
  );
}
