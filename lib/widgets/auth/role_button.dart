import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_image_view.dart';

Widget buildRoleButton(
  BuildContext context, {
  required String label,
  required String iconPath,
  required void Function() onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.textTransparentBlack,
            blurRadius: 4,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(imagePath: iconPath, height: 32, width: 32, fit: BoxFit.contain,),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
        ],
      ),
    ),
  );
}
