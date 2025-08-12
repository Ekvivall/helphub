import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class DropdownItem {
  final String key;
  final String value;

  DropdownItem({required this.key, required this.value});
}

class CustomDropdown extends StatelessWidget {
  const CustomDropdown({
    super.key,
    required this.labelText,
    this.value,
    required this.hintText,
    required this.items,
    required this.onChanged,
    this.labelTextStyle,
    this.containerHeight,
    this.containerPadding,
    this.containerBackgroundColor,
    this.containerBorderColor,
    this.containerBorderWidth,
    this.containerBorderRadius,
    this.dropdownIconColor,
    this.itemTextStyle,
    this.hintTextStyle,
    this.menuMaxHeight,
    this.validator,
    this.showErrorsLive = false,
  });

  final String labelText;

  final String? value;

  final bool showErrorsLive;

  final String hintText;

  final List<DropdownItem> items;

  final ValueChanged<String?> onChanged;

  final TextStyle? labelTextStyle;

  final double? containerHeight;

  final EdgeInsetsGeometry? containerPadding;

  final Color? containerBackgroundColor;

  final Color? containerBorderColor;

  final double? containerBorderWidth;

  final double? containerBorderRadius;

  final Color? dropdownIconColor;

  final TextStyle? itemTextStyle;

  final TextStyle? hintTextStyle;

  final double? menuMaxHeight;

  final String? Function(String? value)? validator;

  @override
  Widget build(BuildContext context) {
    final defaultLabelTextStyle =
        labelTextStyle ??
        TextStyleHelper.instance.title16Bold.copyWith(
          height: 1.2,
          color: appThemeColors.blueAccent,
        );

    final defaultContainerBackgroundColor =
        containerBackgroundColor ?? appThemeColors.backgroundLightGrey;
    final defaultContainerBorderColor =
        containerBorderColor ?? appThemeColors.textMediumGrey;
    final defaultContainerBorderWidth = containerBorderWidth ?? 1.0;
    final defaultContainerBorderRadius = containerBorderRadius ?? 12.0;
    final defaultDropdownIconColor =
        dropdownIconColor ?? appThemeColors.textMediumGrey;

    final defaultHintTextStyle =
        hintTextStyle ??
        TextStyle(color: appThemeColors.textMediumGrey, fontSize: 16);

    final defaultItemTextStyle =
        itemTextStyle ??
        TextStyle(color: appThemeColors.primaryBlack, fontSize: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(labelText, style: defaultLabelTextStyle),
        const SizedBox(height: 8),
        Container(
          //height: containerHeight ?? 42,
          width: double.infinity,
          padding:
              containerPadding ?? const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: defaultContainerBackgroundColor,
            border: Border.all(
              color: defaultContainerBorderColor,
              width: defaultContainerBorderWidth,
            ),
            borderRadius: BorderRadius.circular(defaultContainerBorderRadius),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            hint: Text(hintText, style: defaultHintTextStyle),
            isExpanded: true,
            decoration: InputDecoration(
              border: InputBorder.none,
              focusedBorder: InputBorder.none,
              enabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              filled: false,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 0,
              ),
              isDense: true,
              errorMaxLines: 2,
              errorStyle: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.errorRed,
              ),
            ),
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: defaultDropdownIconColor,
            ),
            menuMaxHeight: menuMaxHeight,
            items: items.map((DropdownItem item) {
              return DropdownMenuItem<String>(
                value: item.key,
                child: Text(item.value, style: defaultItemTextStyle),
              );
            }).toList(),
            onChanged: onChanged,
            validator: validator,
            autovalidateMode: showErrorsLive
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
          ),
        ),
      ],
    );
  }
}
