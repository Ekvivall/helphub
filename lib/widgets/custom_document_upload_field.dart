import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

class CustomDocumentUploadField extends FormField<List<PlatformFile>> {
  CustomDocumentUploadField({
    super.key,
    required String labelText,
    String? description,
    super.onSaved,
    super.validator,
    ValueChanged<List<PlatformFile>>? onChanged,
    List<PlatformFile>? initialFiles,
    bool isLoading = false,
    Color? backgroundColor,
    Color? borderColor,
    double borderWidth = 1.0,
    double borderRadius = 12.0,
    Color? iconColor,
    Color? hintTextColor,
    TextStyle? fileNameTextStyle,
    TextStyle? labelTextStyle,
    TextStyle? descriptionTextStyle,
    String pickButtonText = 'Натисніть, щоб завантажити файл(и)',
    List<String> allowedExtensions = const ['pdf', 'doc', 'docx', 'png', 'jpg', 'xlsx'],
    bool showErrorsLive = false
  }) : super(
    initialValue: initialFiles ?? [],
    autovalidateMode: showErrorsLive ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
    builder: (FormFieldState<List<PlatformFile>> state) {
      final defaultBackgroundColor = backgroundColor ?? appThemeColors.backgroundLightGrey;
      final defaultBorderColor = borderColor ?? appThemeColors.textMediumGrey;
      final defaultIconColor = iconColor ?? appThemeColors.textMediumGrey;
      final defaultHintTextColor = hintTextColor ?? appThemeColors.textMediumGrey;
      final defaultFileNameTextStyle = fileNameTextStyle ??
          TextStyleHelper.instance.title14Regular.copyWith(color: defaultHintTextColor);
      final defaultLabelTextStyle = labelTextStyle ??
          TextStyleHelper.instance.title16Bold.copyWith(
            height: 1.2,
            color: appThemeColors.blueAccent,
          );
      final defaultDescriptionTextStyle = descriptionTextStyle ??
          TextStyleHelper.instance.title14Regular.copyWith(
            height: 1.2,
            color: appThemeColors.primaryBlack,
          );

      String displayText = (state.value != null && state.value!.isNotEmpty)
          ? 'Вибрано: ${state.value!.map((f) => f.name).join(', ')}'
          : pickButtonText;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: defaultLabelTextStyle,
          ),
          const SizedBox(height: 8),

          if (description != null)
            Text(
              description,
              style: defaultDescriptionTextStyle,
            ),
          if (description != null) const SizedBox(height: 8),

          GestureDetector(
            onTap: isLoading
                ? null
                : () async {
              FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: allowedExtensions,
                allowMultiple: true,
              );

              List<PlatformFile> newFiles = result?.files ?? [];
              state.didChange(newFiles);
              if (onChanged != null) {
                onChanged(newFiles);
              }
            },
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 120.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: defaultBackgroundColor,
                border: Border.all(
                  color: state.hasError ? appThemeColors.errorRed : defaultBorderColor,
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
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                state.errorText!,
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
        ],
      );
    },
  );
}