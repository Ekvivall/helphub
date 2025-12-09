
import 'category_chip_model.dart';

enum UserRole { volunteer, organization, admin }
abstract class BaseProfileModel {
  final String? uid;
  final String? email;
  final UserRole? role;
  final String? photoUrl;
  final DateTime? lastSignInAt;
  final DateTime? createdAt;
  final String? city;
  final String? aboutMe;
  final int? projectsCount;
  final int? eventsCount;
  final List<CategoryChipModel>? categoryChips;
  final String? phoneNumber;
  final String? telegramLink;
  final String? instagramLink;

  BaseProfileModel({
    this.uid,
    this.email,
    this.role,
    this.photoUrl,
    this.lastSignInAt,
    this.createdAt,
    this.city,
    this.aboutMe,
    this.projectsCount,
    this.eventsCount,
    this.categoryChips,
    this.phoneNumber,
    this.telegramLink,
    this.instagramLink,
  });

  Map<String, dynamic> toMap();
}
