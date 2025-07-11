
import 'category_chip_model.dart';

enum UserRole { volunteer, organization }
abstract class BaseProfileModel {
  final String? uid;
  final String? email;
  final UserRole? role; // Важливо зберегти роль для розрізнення
  final String? displayName;
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
    this.displayName,
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
    this.instagramLink
  });

  Map<String, dynamic> toMap();
}
