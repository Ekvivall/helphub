import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class CustomInputField extends StatelessWidget {
  const CustomInputField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.isRequired = false,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.height,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.focusedBorderColor,
    this.textColor,
    this.hintTextColor,
    this.fontSize,
  });
  final TextEditingController? controller;

  final String? hintText;

  final String? labelText;

  final bool isRequired;

  final TextInputType inputType;

  final bool isPassword;

  final String? Function(String? value)? validator;

  final Function(String value)? onChanged;

  final Function(String value)? onSubmitted;

  final Widget? prefixIcon;

  final Widget? suffixIcon;

  final List<TextInputFormatter>? inputFormatters;

  final int? maxLength;

  final bool enabled;

  final bool readOnly;

  final double? height;

  final double? borderRadius;

  final Color? backgroundColor;

  final Color? borderColor;

  final Color? focusedBorderColor;

  final Color? textColor;

  final Color? hintTextColor;

  final double? fontSize;

  OutlineInputBorder _buildOutlineInputBorder({
    required Color color,
    required double width,
    required double defaultRadiusValue,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(borderRadius ?? defaultRadiusValue),
      borderSide: BorderSide(
        color: color,
        width: width,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height ?? 42,
      child: TextFormField(
        controller: controller,
        keyboardType: inputType,
        obscureText: isPassword,
        enabled: enabled,
        readOnly: readOnly,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        validator: validator ?? (isRequired ? _defaultValidator : null),
        style: TextStyleHelper.instance.bodyTextRegular.copyWith(
          color: textColor ?? appThemeColors.textMediumGrey,
          fontSize: fontSize,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          hintStyle: TextStyleHelper.instance.bodyTextRegular.copyWith(
            color: hintTextColor ?? appThemeColors.textMediumGrey,
            fontSize: fontSize,
          ),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: backgroundColor ?? appThemeColors.backgroundLightGrey,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: _buildOutlineInputBorder(
            color: borderColor ?? appThemeColors.textMediumGrey,
            width: 1,
            defaultRadiusValue: 12,
          ),
          enabledBorder: _buildOutlineInputBorder(
            color: borderColor ?? appThemeColors.textMediumGrey,
            width: 1,
            defaultRadiusValue: 12,
          ),
          focusedBorder: _buildOutlineInputBorder(
            color: focusedBorderColor ?? appThemeColors.blueAccent,
            width: 2,
            defaultRadiusValue: 12,
          ),
          errorBorder: _buildOutlineInputBorder(
            color: appThemeColors.errorRed,
            width: 1,
            defaultRadiusValue: 12,
          ),
          focusedErrorBorder: _buildOutlineInputBorder(
            color: appThemeColors.errorRed,
            width: 2,
            defaultRadiusValue: 12,
          ),
          counterText: maxLength != null ? null : "",
        ),
      ),
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Це поле є обов\'язковим';
    }
    return null;
  }
}