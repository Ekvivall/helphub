import 'package:flutter/material.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class CategoryChipWidget extends StatelessWidget {
  final CategoryChipModel chip;
  final bool isSelected;

  const CategoryChipWidget({
    super.key,
    required this.chip,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 109,
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
          if (isSelected) Icon(Icons.check, color: appThemeColors.successGreen, size: 20,),
          Text(
            chip.title ?? '',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: isSelected
                  ? appThemeColors.successGreen
                  : chip.textColor,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
