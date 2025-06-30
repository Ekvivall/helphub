import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class CustomCheckboxWithText extends StatelessWidget {
  const CustomCheckboxWithText({
    super.key,
    required this.value,
    required this.onChanged,
    required this.text,
    this.activeColor,
    this.checkColor,
    this.textStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final bool value;

  final ValueChanged<bool?> onChanged;

  final String text;

  final Color? activeColor;

  final Color? checkColor;

  final TextStyle? textStyle;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final defaultActiveColor = activeColor ?? appThemeColors.blueAccent;
    final defaultCheckColor = checkColor ?? appThemeColors.backgroundLightGrey;
    final defaultTextStyle = textStyle ??
        TextStyleHelper.instance.title13Regular.copyWith(
          height: 1.2,
          color: appThemeColors.primaryBlack,
        );

    return Row(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: defaultActiveColor,
          checkColor: defaultCheckColor,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        Expanded(
          child: Text(
            text,
            style: defaultTextStyle,
          ),
        ),
      ],
    );
  }
}