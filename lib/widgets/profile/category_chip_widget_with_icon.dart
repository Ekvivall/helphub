import 'package:flutter/material.dart';
import 'package:helphub/widgets/custom_image_view.dart';

import '../../models/category_chip_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class CategoryChipWidgetWithIcon extends StatelessWidget {
  final CategoryChipModel chip;
  final bool isSelected;

  const CategoryChipWidgetWithIcon({
    super.key,
    required this.chip,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      width: 171,
      decoration: BoxDecoration(
        color: isSelected
            ? appThemeColors.primaryWhite
            : chip.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: BoxBorder.all(
          color: isSelected ? appThemeColors.lightGreenColor : appThemeColors.appBarBg,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSelected) Icon(Icons.check, color: appThemeColors.successGreen, size: 30,),
          CustomImageView(imagePath: chip.imagePath, height: 35, width: 35,),
          SizedBox(width: 14),
          Text(
            chip.title ?? '',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: isSelected
                  ? appThemeColors.successGreen
                  : chip.textColor,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
