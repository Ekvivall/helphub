import 'package:flutter/material.dart';

import '../models/base_profile_model.dart';
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
    return GestureDetector(
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
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: size,
            backgroundColor: appThemeColors.lightGreenColor,
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
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
          if (role == UserRole.volunteer && frame != null && frame!.isNotEmpty)
            CustomImageView(
              imagePath: frame!,
              height: size + 10,
              width: size + 10,
              fit: BoxFit.contain,
            ),
        ],
      ),
    );
  }
}
