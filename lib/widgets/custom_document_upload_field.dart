import 'package:flutter/material.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class CustomImageUploadField extends FormField<File> {
  CustomImageUploadField({
    super.key,
    required String labelText,
    ValueChanged<File?>? onChanged,
    super.onSaved,
    super.validator,
    super.initialValue,
    String? initialImageUrl, // Додаємо поле для існуючого URL фото
  }) : super(
    builder: (FormFieldState<File> state) {
      Future<void> pickImage() async {
        final ImagePicker picker = ImagePicker();
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxHeight: 1080,
          maxWidth: 1080,
          imageQuality: 85,
        );
        if (image != null) {
          final file = File(image.path);

          // Перевірка розміру файлу (10 МБ максимум)
          final int fileSizeInBytes = await file.length();
          final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

          if (fileSizeInMB > 10) {
            ScaffoldMessenger.of(state.context).showSnackBar(
              SnackBar(
                content: Text('Розмір файлу повинен бути менше 10 МБ'),
                backgroundColor: appThemeColors.errorRed,
              ),
            );
            return;
          }

          state.didChange(file);
          onChanged?.call(file);
        }
      }

      void clearImage() {
        state.didChange(null);
        onChanged?.call(null);
      }

      // Визначаємо, що показувати: новий файл, існуючий URL або плейсхолдер
      final hasNewFile = state.value != null;
      final hasExistingImage = initialImageUrl != null && initialImageUrl.isNotEmpty;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            labelText,
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          const SizedBox(height: 8),

          if (hasNewFile)
          // Показуємо новий обраний файл
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.file(
                      state.value!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: clearImage,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: appThemeColors.errorRed.withAlpha(177),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            Icons.close,
                            color: appThemeColors.primaryWhite,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appThemeColors.blueAccent.withAlpha(204),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Нове фото',
                          style: TextStyleHelper.instance.title13Regular.copyWith(
                            color: appThemeColors.primaryWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (hasExistingImage)
          // Показуємо існуюче фото з URL
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    Image.network(
                      initialImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                            color: appThemeColors.blueAccent,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: appThemeColors.blueMixedColor.withAlpha(77),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: appThemeColors.errorRed,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: appThemeColors.errorRed,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Помилка завантаження фото',
                                style: TextStyleHelper.instance.title14Regular
                                    .copyWith(
                                  color: appThemeColors.errorRed,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: appThemeColors.blueAccent.withAlpha(204),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.edit,
                            color: appThemeColors.primaryWhite,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: appThemeColors.successGreen.withAlpha(204),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Поточне фото',
                          style: TextStyleHelper.instance.title13Regular.copyWith(
                            color: appThemeColors.primaryWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
          // Плейсхолдер для вибору нового фото
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: appThemeColors.blueMixedColor.withAlpha(77),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: state.hasError
                        ? appThemeColors.errorRed
                        : appThemeColors.backgroundLightGrey,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo,
                      color: appThemeColors.backgroundLightGrey,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Додати фото',
                      style: TextStyleHelper.instance.title14Regular
                          .copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'JPG, PNG до 10 МБ',
                      style: TextStyleHelper.instance.title13Regular
                          .copyWith(
                        color: appThemeColors.backgroundLightGrey.withAlpha(128),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 12.0),
              child: Text(
                state.errorText!,
                style: TextStyle(
                  color: appThemeColors.errorRed,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    },
  );
}