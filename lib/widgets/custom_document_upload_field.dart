import 'package:flutter/material.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

class CustomDocumentUploadField extends StatelessWidget {
  const CustomDocumentUploadField({
    super.key,
    required this.onTap,
    this.fileNames,
    this.isLoading = false,
    this.label,
    this.description,
    this.height = 120.0,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = 12.0,
    this.iconColor,
    this.hintTextColor,
    this.fileNameTextStyle,
    this.labelTextStyle,
    this.descriptionTextStyle,
  });

  final VoidCallback onTap;

  final List<String>? fileNames;

  final bool isLoading;

  final String? label;

  final String? description;

  final double height;

  final Color? backgroundColor;

  final Color? borderColor;

  final double borderWidth;

  final double borderRadius;

  final Color? iconColor;

  final Color? hintTextColor;

  final TextStyle? fileNameTextStyle;

  final TextStyle? labelTextStyle;

  final TextStyle? descriptionTextStyle;

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? appThemeColors.backgroundLightGrey;
    final defaultBorderColor = borderColor ?? appThemeColors.textMediumGrey;
    final defaultIconColor = iconColor ?? appThemeColors.textMediumGrey;
    final defaultHintTextColor = hintTextColor ?? appThemeColors.textMediumGrey;
    final defaultFileNameTextStyle = fileNameTextStyle ??
        TextStyleHelper.instance.title14Regular.copyWith(color: defaultHintTextColor);
    final defaultLabelTextStyle = labelTextStyle ??
        TextStyleHelper.instance.title16ExtraBold.copyWith(
          height: 1.2,
          color: appThemeColors.blueAccent,
        );
    final defaultDescriptionTextStyle = descriptionTextStyle ??
        TextStyleHelper.instance.title14Regular.copyWith(
          height: 1.2,
          color: appThemeColors.textMediumGrey,
        );

    String displayText = (fileNames != null && fileNames!.isNotEmpty)
        ? 'Вибрано: ${fileNames!.join(', ')}'
        : 'Натисніть, щоб завантажити файл(и)';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: defaultLabelTextStyle,
          ),
        if (label != null) const SizedBox(height: 8),

        if (description != null)
          Text(
            description!,
            style: defaultDescriptionTextStyle,
          ),
        if (description != null) const SizedBox(height: 8),

        GestureDetector(
          onTap: isLoading ? null : onTap,
          child: Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: defaultBackgroundColor,
              border: Border.all(
                color: defaultBorderColor,
                width: borderWidth,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload,
                  size: 40,
                  color: defaultIconColor,
                ),
                const SizedBox(height: 8),
                Text(
                  displayText,
                  style: defaultFileNameTextStyle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isLoading)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: appThemeColors.blueAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}