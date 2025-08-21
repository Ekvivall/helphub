import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/text_style_helper.dart';
import '../theme/theme_helper.dart';

class CustomMultiImageUploadField extends StatefulWidget {
  final String labelText;
  final ValueChanged<List<File>>? onChanged;
  final List<String>? initialImageUrls;

  const CustomMultiImageUploadField({
    super.key,
    required this.labelText,
    this.onChanged,
    this.initialImageUrls,
  });

  @override
  State<CustomMultiImageUploadField> createState() =>
      _CustomMultiImageUploadFieldState();
}

class _CustomMultiImageUploadFieldState
    extends State<CustomMultiImageUploadField> {
  final List<File> _selectedImages = [];

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage(
      maxHeight: 1080,
      maxWidth: 1080,
      imageQuality: 85,
    );

    final files = images.map((image) => File(image.path)).toList();
    setState(() {
      _selectedImages.addAll(files);
    });
    widget.onChanged?.call(_selectedImages);
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onChanged?.call(_selectedImages);
  }

  @override
  Widget build(BuildContext context) {
    final hasImages = _selectedImages.isNotEmpty ||
        (widget.initialImageUrls?.isNotEmpty ?? false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.labelText,
          style: TextStyleHelper.instance.title16Bold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        const SizedBox(height: 8),

        // Кнопка додавання фото
        GestureDetector(
          onTap: _pickImages,
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: appThemeColors.blueMixedColor.withAlpha(77),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: appThemeColors.backgroundLightGrey,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate,
                  color: appThemeColors.backgroundLightGrey,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  'Додати фото',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG до 10 МБ кожне',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey.withAlpha(128),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Комбінований список обраних та існуючих фотографій
        if (hasImages) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + (widget.initialImageUrls?.length ?? 0),
              itemBuilder: (context, index) {
                final isLocalImage = index < _selectedImages.length;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  height: 100,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isLocalImage
                            ? Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        )
                            : Image.network(
                          widget.initialImageUrls![
                          index - _selectedImages.length],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          loadingBuilder:
                              (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 100,
                              height: 100,
                              color: appThemeColors.blueMixedColor
                                  .withAlpha(77),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: appThemeColors.blueAccent,
                                  value:
                                  loadingProgress.expectedTotalBytes !=
                                      null
                                      ? loadingProgress
                                      .cumulativeBytesLoaded /
                                      loadingProgress
                                          .expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 100,
                              height: 100,
                              color:
                              appThemeColors.errorRed.withAlpha(77),
                              child: Icon(
                                Icons.error,
                                color: appThemeColors.errorRed,
                              ),
                            );
                          },
                        ),
                      ),
                      // Кнопка видалення тільки для локальних файлів
                      if (isLocalImage)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: appThemeColors.errorRed.withAlpha(200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                color: appThemeColors.primaryWhite,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}