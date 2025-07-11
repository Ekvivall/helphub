import 'package:flutter/material.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class StatisticItemWidget extends StatelessWidget {
  final int? value;
  final String? label;

  const StatisticItemWidget({super.key, this.value, this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value == null ? '0' : value.toString(),
          style: TextStyleHelper.instance.title32Bold.copyWith(
            color: appThemeColors.lightGreenColor,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label ?? '',
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ],
    );
  }
}
