import 'package:flutter/material.dart';

import '../data/models/base_profile_model.dart';
import '../routes/app_router.dart';
import '../theme/theme_helper.dart';
import 'custom_image_view.dart';

class UserAvatarWithFrame extends StatelessWidget {
  final String? photoUrl;
  final String? frame;
  final UserRole? role;
  final double size;
  final String? uid;

  const UserAvatarWithFrame({
    super.key,
    this.photoUrl,
    this.frame,
    required this.size,
    required this.role,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final bool isVolunteerWithFrame =
        role == UserRole.volunteer && frame != null && frame!.isNotEmpty;
    final double widgetHeight = isVolunteerWithFrame
        ? (size * 2.35)
        : (size * 2);
    final double widgetWidth = isVolunteerWithFrame
        ? (size * 2.35)
        : (size * 2);
    final double avatarRadius = size * (isVolunteerWithFrame ? 0.92 : 1.0);
    return SizedBox(
      height: widgetHeight,
      width: widgetWidth,
      child: GestureDetector(
        onTap: () {
          if (uid == null) return;
          if (role == UserRole.volunteer) {
            Navigator.of(
              context,
            ).pushNamed(AppRoutes.volunteerProfileScreen, arguments: uid);
          } else if (role == UserRole.organization) {
            Navigator.of(
              context,
            ).pushNamed(AppRoutes.organizationProfileScreen, arguments: uid);
          } else {
            Navigator.of(context).pushNamed(AppRoutes.loginScreen);
          }
        },
        child: Stack(
          children: [
            Positioned(
              top: isVolunteerWithFrame ? size * 0.3 : 0,
              left: isVolunteerWithFrame ? size * 0.2 : 0,
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: appThemeColors.lightGreenColor,
                backgroundImage: (photoUrl != null)
                    ? (photoUrl!.startsWith('http') ||
                              photoUrl!.startsWith('https'))
                          ? NetworkImage(photoUrl!)
                          : AssetImage(photoUrl!) as ImageProvider
                    : null,
                child: photoUrl == null && role == UserRole.volunteer
                    ? Icon(
                        Icons.person,
                        size: size,
                        color: appThemeColors.primaryWhite,
                      )
                    : photoUrl == null && role == UserRole.organization
                    ? Icon(
                        Icons.business,
                        size: size,
                        color: appThemeColors.primaryWhite,
                      )
                    : null,
              ),
            ),
            if (isVolunteerWithFrame)
              CustomImageView(
                imagePath: frame!,
                height: widgetHeight,
                fit: BoxFit.contain,
              ),
          ],
        ),
      ),
    );
  }
}
