import 'package:flutter/material.dart';
import 'package:helphub/data/models/trust_badge_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_image_view.dart';

class TrustBadgeWidget extends StatelessWidget {
  final TrustBadgeModel badge;

  const TrustBadgeWidget({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    if (badge.title?.isEmpty ?? true) {
      return Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: appThemeColors.blueTransparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: appThemeColors.blueTransparent),
        ),
        child: Center(
          child: CustomImageView(
            imagePath: badge.imagePath ?? '',
            height: 20,
            width: 32,
          ),
        ),
      );
    }
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Color(0x7FF8F9FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: appThemeColors.blueTransparent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomImageView(
            imagePath: badge.imagePath ?? '',
            height: 32,
            width: 24,
          ),
          SizedBox(width: 8),
          Text(
            badge.title ?? '',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ],
      ),
    );
  }
}
