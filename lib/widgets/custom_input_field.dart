import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class CustomInputField extends StatefulWidget {
  const CustomInputField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.isRequired = false,
    this.inputType = TextInputType.text,
    this.isPassword = false,
    this.showErrorsLive = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffixIcon,
    this.inputFormatters,
    this.errorColor,
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
    this.minLines,
    this.maxLines,
    this.initialValue
  });

  final TextEditingController? controller;

  final String? hintText;

  final String? labelText;

  final bool isRequired;

  final TextInputType inputType;

  final bool isPassword;

  final bool showErrorsLive;

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

  final Color? errorColor;

  final Color? hintTextColor;

  final double? fontSize;

  final int? minLines;

  final int? maxLines;

  final String? initialValue;

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.isPassword;
  }

  OutlineInputBorder _buildOutlineInputBorder({
    required Color color,
    required double width,
    required double defaultRadiusValue,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(
        widget.borderRadius ?? defaultRadiusValue,
      ),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      minLines: widget.minLines,
      initialValue: widget.initialValue,
      maxLines: widget.maxLines,
      controller: widget.controller,
      keyboardType: widget.inputType,
      obscureText: _isObscure && widget.isPassword,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      autovalidateMode: widget.showErrorsLive ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      validator:
          widget.validator ?? (widget.isRequired ? _defaultValidator : null),
      style: TextStyleHelper.instance.bodyTextRegular.copyWith(
        color: widget.textColor ?? appThemeColors.textMediumGrey,
        fontSize: widget.fontSize,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        labelText: widget.labelText,
        hintStyle: TextStyleHelper.instance.bodyTextRegular.copyWith(
          color: widget.hintTextColor ?? appThemeColors.textMediumGrey,
          fontSize: widget.fontSize,
        ),
        labelStyle: TextStyleHelper.instance.bodyTextRegular.copyWith(
          color: widget.textColor ?? appThemeColors.primaryBlack,
          fontSize: widget.fontSize,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () {
                  setState(() {
                    _isObscure = !_isObscure;
                  });
                },
                icon: Icon(
                  _isObscure ? Icons.visibility_off : Icons.visibility,
                  color: appThemeColors.textMediumGrey,
                ),
              )
            : widget.suffixIcon,
        filled: true,
        fillColor: widget.backgroundColor ?? appThemeColors.backgroundLightGrey,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: _buildOutlineInputBorder(
          color: widget.borderColor ?? appThemeColors.textMediumGrey,
          width: 1,
          defaultRadiusValue: 12,
        ),
        enabledBorder: _buildOutlineInputBorder(
          color: widget.borderColor ?? appThemeColors.textMediumGrey,
          width: 1,
          defaultRadiusValue: 12,
        ),
        focusedBorder: _buildOutlineInputBorder(
          color: widget.focusedBorderColor ?? appThemeColors.blueAccent,
          width: 2,
          defaultRadiusValue: 12,
        ),
        errorBorder: _buildOutlineInputBorder(
          color: widget.errorColor??appThemeColors.errorLight,
          width: 1,
          defaultRadiusValue: 12,
        ),
        focusedErrorBorder: _buildOutlineInputBorder(
          color: widget.errorColor??appThemeColors.errorLight,
          width: 2,
          defaultRadiusValue: 12,
        ),
        errorMaxLines: 2,
        errorStyle: TextStyleHelper.instance.title13Regular.copyWith(
          color: widget.errorColor??appThemeColors.errorLight
        ),
        counterText: widget.maxLength != null ? null : "",
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
