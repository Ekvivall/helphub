import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/theme/text_style_helper.dart';

class PhotoOptionsBottomSheet extends StatelessWidget {
  final ProfileViewModel viewModel;
  final ImagePicker picker;
  final Function(VolunteerModel) onSelectAvatar;

  const PhotoOptionsBottomSheet({
    super.key,
    required this.viewModel,
    required this.picker,
    required this.onSelectAvatar,
  });

  Future<void> _pickImage(ImageSource source, BuildContext context) async {
    Navigator.pop(context);
    try {
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        await viewModel.updateProfilePhoto(File(image.path));
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final volunteer = viewModel.user is VolunteerModel
        ? viewModel.user as VolunteerModel
        : null;
    return Container(
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: appThemeColors.grey200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text('Виберіть спосіб', style: TextStyleHelper.instance.title18Bold),
          const SizedBox(height: 20),
          ListTile(
            leading: Icon(
              Icons.photo_library,
              color: appThemeColors.blueAccent,
            ),
            title: Text(
              'Вибрати з галереї',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            onTap: () => _pickImage(ImageSource.gallery, context),
          ),
          ListTile(
            leading: Icon(Icons.camera_alt, color: appThemeColors.blueAccent),
            title: Text(
              'Зроби фото',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            onTap: () => _pickImage(ImageSource.camera, context),
          ),
          if (volunteer != null)
            ListTile(
              leading: Icon(Icons.face, color: appThemeColors.lightGreenColor),
              title: Text(
                'Вибрати аватар',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                onSelectAvatar(volunteer);
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
