import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_input_field.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType? inputType;
  final Function(String)? onChanged;
  final String? Function(String? value)? validator;
  final bool showErrorsLive;
  final Color? labelColor;
  final double height;
  final int? minLines;
  final int? maxLines;
  final bool readOnly;
  final Color? fillColor;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isRequired;
  final List<TextInputFormatter>? inputFormatters;
  final Color? errorColor;
  final String? initialValue;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.controller,
    this.isPassword = false,
    this.inputType,
    this.onChanged,
    this.validator,
    this.showErrorsLive = false,
    this.labelColor,
    this.height = 42,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.fillColor,
    this.prefixIcon,
    this.suffixIcon,
    this.isRequired = true,
    this.inputFormatters,
    this.errorColor, this.initialValue
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleHelper.instance.title16Bold.copyWith(
            color: labelColor ?? appThemeColors.blueAccent,
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        CustomInputField(
          controller: controller,
          hintText: hintText,
          inputType: inputType!,
          isRequired: isRequired,
          isPassword: isPassword,
          backgroundColor: fillColor ?? appThemeColors.backgroundLightGrey,
          borderColor: appThemeColors.textMediumGrey,
          focusedBorderColor: appThemeColors.blueAccent,
          textColor: appThemeColors.primaryBlack,
          hintTextColor: appThemeColors.textMediumGrey,
          fontSize: 16,
          height: height,
          borderRadius: 12,
          onChanged: onChanged,
          validator: validator,
          showErrorsLive: showErrorsLive,
          minLines: minLines,
          maxLines: maxLines,
          readOnly: readOnly,
          prefixIcon: prefixIcon,
          inputFormatters: inputFormatters,
          errorColor: errorColor,
          initialValue: initialValue,
          suffixIcon: suffixIcon,
        ),
      ],
    );
  }
}
