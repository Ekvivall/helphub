import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/validators/auth_validator.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:helphub/widgets/custom_text_field.dart';
import 'package:helphub/widgets/profile/category_chip_widget_with_icon.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../data/models/volunteer_model.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_dropdown.dart';
import '../../widgets/user_avatar_with_frame.dart';

class EditUserProfileScreen extends StatefulWidget {
  const EditUserProfileScreen({super.key});

  @override
  State<EditUserProfileScreen> createState() => _EditUserProfileScreenState();
}

class _EditUserProfileScreenState extends State<EditUserProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final MaskTextInputFormatter _phoneNumberFormatter = MaskTextInputFormatter(
    mask: '+380 ## ### ## ##',
    filter: {'#': RegExp(r'[0-9]')},
    type: MaskAutoCompletionType.lazy,
  );
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<ProfileViewModel>(context, listen: false);
    if (!viewModel.isEditing) {
      viewModel.toggleEditing();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Висота кнопок та відступів знизу для футера
    final double bottomButtonHeight = 44.0;
    final double bottomButtonPadding = 16.0;
    final double totalBottomSpace =
        bottomButtonHeight + (bottomButtonPadding * 2);
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.user == null) {
          return Center(
            child: CircularProgressIndicator(
              color: appThemeColors.lightGreenColor,
            ),
          );
        }
        final BaseProfileModel user = viewModel.user!;
        return Scaffold(
          backgroundColor: appThemeColors.blueAccent,
          appBar: AppBar(
            backgroundColor: appThemeColors.appBarBg,
            leading: IconButton(
              onPressed: () {
                viewModel.cancelEditing();
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back,
                size: 40,
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Редагувати профіль',
                  style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.9, -0.4),
                end: Alignment(-0.9, 0.4),
                colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
              ),
            ),
            child: Stack(
              children: [
                // Основний прокручуваний контент
                SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.only(bottom: totalBottomSpace),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основний контент форми
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Блок фото профілю та рамки
                              _buildProfilePictureAndFrameSection(
                                user,
                                viewModel,
                              ),
                              const SizedBox(height: 16),
                              if (user.role == UserRole.volunteer)
                                CustomTextField(
                                  label: 'Ім\'я та прізвище',
                                  hintText: 'Введіть ваше ім\'я та прізвище',
                                  controller: viewModel.fullNameController,
                                  inputType: TextInputType.name,
                                  validator: AuthValidator.validateFullName,
                                  labelColor:
                                      appThemeColors.backgroundLightGrey,
                                ),
                              if (user.role == UserRole.organization)
                                CustomTextField(
                                  label: 'Назва організації',
                                  hintText: 'Введіть назву організації',
                                  controller:
                                      viewModel.organizationNameController,
                                  inputType: TextInputType.text,
                                  validator:
                                      AuthValidator.validateOrganizationName,
                                  labelColor:
                                      appThemeColors.backgroundLightGrey,
                                ),
                              const SizedBox(height: 16),
                              if (user.role == UserRole.volunteer)
                                CustomTextField(
                                  label: 'Нікнейм',
                                  hintText: 'Введіть ваш нікнейм',
                                  controller: viewModel.nicknameController,
                                  inputType: TextInputType.text,
                                  labelColor:
                                      appThemeColors.backgroundLightGrey,
                                  isRequired: false,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Будь ласка, введіть нікнейм';
                                    }
                                    return null;
                                  },
                                ),
                              if (user.role == UserRole.organization)
                                CustomTextField(
                                  label: 'Вебсайт',
                                  hintText: 'Введіть посилання на ваш вебсайт',
                                  controller: viewModel.websiteController,
                                  inputType: TextInputType.url,
                                  labelColor:
                                      appThemeColors.backgroundLightGrey,
                                  validator: AuthValidator.validateWebsite,
                                  isRequired: false,
                                ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Електронна пошта',
                                hintText: viewModel.user?.email ?? 'Не вказано',
                                controller: TextEditingController(
                                  text: viewModel.user?.email ?? 'Не вказано',
                                ),
                                inputType: TextInputType.emailAddress,
                                readOnly: true,
                                fillColor: appThemeColors.primaryWhite
                                    .withAlpha(170),
                                labelColor: appThemeColors.backgroundLightGrey,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Телефон',
                                hintText: 'Введіть ваш номер телефону',
                                controller: viewModel.phoneNumberController,
                                inputType: TextInputType.phone,
                                validator: AuthValidator.validatePhoneNumber,
                                labelColor: appThemeColors.backgroundLightGrey,
                                isRequired: false,
                                inputFormatters: [_phoneNumberFormatter],
                              ),
                              const SizedBox(height: 16),
                              CustomDropdown(
                                labelText: 'Місто',
                                value: viewModel.selectedCity,
                                hintText: 'Оберіть місто',
                                items: Constants.cities.map((String item) {
                                  return DropdownItem(key: item, value: item);
                                }).toList(),
                                onChanged: (String? newValue) {
                                  if (newValue != null) {
                                    viewModel.updateCity(newValue);
                                  }
                                },
                                menuMaxHeight: 200,
                                validator: AuthValidator.validateSelectedCity,
                                labelTextStyle: TextStyleHelper
                                    .instance
                                    .title16Bold
                                    .copyWith(
                                      height: 1.2,
                                      color: appThemeColors.backgroundLightGrey,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: user.role == UserRole.volunteer
                                    ? 'Про себе'
                                    : 'Про фонд',
                                hintText: user.role == UserRole.volunteer
                                    ? 'Розкажіть про себе...'
                                    : 'Розкажіть про фонд...',
                                controller: viewModel.aboutMeController,
                                inputType: TextInputType.multiline,
                                labelColor: appThemeColors.backgroundLightGrey,
                                minLines: 3,
                                maxLines: null,
                                isRequired: false,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                user.role == UserRole.volunteer
                                    ? 'Сфери інтересів'
                                    : 'Категорії фонду',
                                style: TextStyleHelper.instance.title16Bold
                                    .copyWith(
                                      color: appThemeColors.backgroundLightGrey,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _buildInterestsSection(viewModel),
                              const SizedBox(height: 24),
                              CustomTextField(
                                label: 'Посилання на Telegram',
                                hintText: '@ваш_нік_телеграм',
                                controller: viewModel.telegramLinkController,
                                inputType: TextInputType.url,
                                labelColor: appThemeColors.backgroundLightGrey,
                                prefixIcon: Icon(
                                  Icons.telegram,
                                  color: appThemeColors.textMediumGrey,
                                ),
                                isRequired: false,
                              ),
                              const SizedBox(height: 16),
                              CustomTextField(
                                label: 'Посилання на Instagram',
                                hintText: '@ваш_нік_інстаграм',
                                controller: viewModel.instagramLinkController,
                                inputType: TextInputType.url,
                                labelColor: appThemeColors.backgroundLightGrey,
                                prefixIcon: CustomImageView(
                                  imagePath: ImageConstant.instagramIcon,
                                  height: 12,
                                  width: 12,
                                  margin: EdgeInsets.all(10),
                                ),
                                isRequired: false,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    color: appThemeColors.bottomBg,
                    padding: EdgeInsets.all(bottomButtonPadding),
                    child: Row(
                      children: [
                        Expanded(
                          child: CustomElevatedButton(
                            text: 'Скасувати',
                            onPressed: () {
                              viewModel.cancelEditing();
                              Navigator.of(context).pop();
                            },
                            backgroundColor: appThemeColors.backgroundLightGrey,
                            textStyle: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.errorRed),
                            borderColor: appThemeColors.errorRed,
                            borderRadius: 12,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomElevatedButton(
                            text: 'Зберегти',
                            onPressed: () async {
                              if (_formKey.currentState!.validate()) {
                                bool success = await viewModel.updateUserData();
                                if (success) {
                                  Constants.showSuccessMessage(
                                    context,
                                    'Профіль успішно оновлено!',
                                  );
                                  Navigator.of(context).pop();
                                } else {
                                  Constants.showErrorMessage(
                                    context,
                                    'Нікнейм "${viewModel.nicknameController.text.trim()}" вже зайнятий. Будь ласка, виберіть інший.',
                                  );
                                }
                              }
                            },
                            backgroundColor: appThemeColors.successGreen,
                            textStyle: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryWhite),
                            borderRadius: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfilePictureAndFrameSection(
    BaseProfileModel user,
    ProfileViewModel viewModel,
  ) {
    final VolunteerModel? volunteer = user is VolunteerModel ? user : null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UserAvatarWithFrame(
          size: 50,
          role: user.role,
          photoUrl: user.photoUrl,
          frame: volunteer?.frame,
          uid: null,
        ),
        const SizedBox(width: 16),
        Column(
          children: [
            CustomElevatedButton(
              text: 'Змінити фото',
              onPressed: () async {
                final XFile? image = await _picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (image != null) {
                  await viewModel.updateProfilePhoto(File(image.path));
                }
              },
              backgroundColor: appThemeColors.textMediumGrey,
              borderRadius: 12,
              textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
              width: 150,
              height: 35,
            ),
            const SizedBox(height: 16),
            if (user.role == UserRole.volunteer)
              CustomElevatedButton(
                text: 'Змінити рамку',
                onPressed: () {
                  //TODO: Додати логіку зміни рамки,
                },
                backgroundColor: appThemeColors.textMediumGrey,
                borderRadius: 12,
                textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
                width: 150,
                height: 35,
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildInterestsSection(ProfileViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 18,
          runSpacing: 8,
          children: viewModel.availableInterests.map((interest) {
            final bool isSelected = viewModel.selectedInterests.any(
              (selected) => selected.title == interest.title,
            );
            return GestureDetector(
              onTap: () {
                viewModel.toggleInterest(interest);
              },
              child: CategoryChipWidgetWithIcon(
                chip: interest,
                isSelected: isSelected,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
