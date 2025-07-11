import 'package:flutter/material.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class CategoryChipWidget extends StatelessWidget {
  final CategoryChipModel chip;

  const CategoryChipWidget({super.key, required this.chip});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      height: 28,
      width: 100,
      decoration: BoxDecoration(
        color:
            chip.backgroundColor ??
            appThemeColors.blueTransparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          chip.title ?? '',
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color:
                chip.textColor ??
                appThemeColors.primaryWhite,
          ),
        ),
      ),
    );
  }
}
