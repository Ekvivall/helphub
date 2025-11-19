import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_image_view.dart';

import '../../data/models/medal_model.dart';

class MedalItemWidget extends StatelessWidget {
  final MedalModel medalItemModel;

  const MedalItemWidget({super.key, required this.medalItemModel});

  @override
  Widget build(BuildContext context) {
    Color medalColor;
    switch (medalItemModel.type) {
      case MedalType.gold:
        medalColor = appThemeColors.goldColor;
        break;
      case MedalType.silver:
        medalColor = Color(0xFFC0C0C0);
        break;
      case MedalType.bronze:
        medalColor = Color(0xFFCD7F32);
        break;
    }
    return Container(
      width: 100,
      margin: EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: medalColor.withAlpha(48),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: medalColor, width: 2),
      ),
      padding: EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomImageView(
            imagePath: medalItemModel.iconPath,
            height: 80,
            width: 80,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 4),
          Text(
            '${medalItemModel.place} місце',
            style: TextStyleHelper.instance.title13Regular.copyWith(
              color: appThemeColors.primaryBlack,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            medalItemModel.seasonName,
            style: TextStyleHelper.instance.title13Regular.copyWith(
              color: appThemeColors.primaryBlack,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}
