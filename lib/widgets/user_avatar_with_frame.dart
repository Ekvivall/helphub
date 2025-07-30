import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/base_profile_model.dart';
import '../theme/theme_helper.dart';
import 'custom_image_view.dart';

class UserAvatarWithFrame extends StatelessWidget{
  final String? photoUrl;
  final String? frame;
  final UserRole? role;
  final double size;
  const UserAvatarWithFrame({super.key, this.photoUrl, this.frame, required this.size, this.role});

  @override
  Widget build(BuildContext context) {
    return  Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: size,
          backgroundColor: appThemeColors.lightGreenColor,
          backgroundImage: photoUrl != null
              ? NetworkImage(photoUrl!)
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
        if (role == UserRole.volunteer &&
            frame != null &&
            frame!.isNotEmpty)
          CustomImageView(
            imagePath: frame!,
            height: size + 10,
            width: size + 10,
            fit: BoxFit.contain,
          ),
      ],
    );
  }

}