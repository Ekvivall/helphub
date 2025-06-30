import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_input_field.dart';

class AuthTextField extends StatelessWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType? inputType;
  final Function(String)? onChanged;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
    this.inputType,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyleHelper.instance.title16ExtraBold.copyWith(
            height: 1.2,
          ),
        ),
        SizedBox(height: 8),
        CustomInputField(
          controller: controller,
          hintText: hintText,
          inputType: inputType!,
          isRequired: true,
          isPassword: isPassword,
          backgroundColor: appThemeColors.backgroundLightGrey,
          borderColor: appThemeColors.textMediumGrey,
          focusedBorderColor: appThemeColors.blueAccent,
          textColor: appThemeColors.primaryBlack,
          hintTextColor: appThemeColors.textMediumGrey,
          fontSize: 16,
          height: 42,
          borderRadius: 12,
          onChanged: onChanged,
        ),
      ],
    );
  }
}