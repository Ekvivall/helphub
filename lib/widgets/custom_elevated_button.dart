import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
class CustomElevatedButton extends StatelessWidget {
  const CustomElevatedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 48.0,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.textStyle,
    this.loadingIndicatorColor,
  });

  final String text;

  final VoidCallback? onPressed;

  final bool isLoading;

  final double width;

  final double height;

  final Color? backgroundColor;

  final Color? foregroundColor;

  final double? borderRadius;

  final TextStyle? textStyle;

  final Color? loadingIndicatorColor;

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor = backgroundColor ?? appThemeColors.blueAccent;
    final defaultForegroundColor = foregroundColor ?? appThemeColors.backgroundLightGrey;
    final defaultBorderRadius = borderRadius ?? 8.0;
    final defaultTextStyle = textStyle ??
        TextStyleHelper.instance.title16ExtraBold.copyWith(
          height: 1.2,
          color: appThemeColors.backgroundLightGrey,
        );
    final defaultLoadingIndicatorColor = loadingIndicatorColor ?? appThemeColors.backgroundLightGrey;

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: defaultBackgroundColor,
          foregroundColor: defaultForegroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultBorderRadius),
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator(
          color: defaultLoadingIndicatorColor,
        )
            : Text(
          text,
          style: defaultTextStyle,
        ),
      ),
    );
  }
}