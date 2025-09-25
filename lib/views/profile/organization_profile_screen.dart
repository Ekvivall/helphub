import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:helphub/widgets/profile/fundraiser_application_item_org_widget.dart';
import 'package:helphub/widgets/profile/trust_badge_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/friend_service.dart';
import '../../core/utils/constants.dart';
import '../../core/utils/image_constant.dart';
import '../../models/base_profile_model.dart';
import '../../models/organization_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/fundraiser_application/fundraiser_application_view_model.dart';
import '../../view_models/profile/profile_view_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/profile/active_fundraising_item.dart';
import '../../widgets/profile/statistic_item_widget.dart';
import '../../widgets/profile/latest_activities.dart';

class OrganizationProfileScreen extends StatefulWidget {
  const OrganizationProfileScreen({super.key, this.userId});

  final String? userId; //ID користувача, чий профіль переглядаємо

  @override
  State<OrganizationProfileScreen> createState() =>
      _OrganizationProfileScreenState();
}

class _OrganizationProfileScreenState extends State<OrganizationProfileScreen> {
  final TextEditingController _rejectionReasonController =
      TextEditingController();

  @override
  void dispose() {
    _rejectionReasonController.dispose();
    super.dispose();
  }

  final ImagePicker _picker = ImagePicker();

  Future<void> _rejectApplication(
    String applicationId,
    BuildContext context,
  ) async {
    if (_rejectionReasonController.text.trim().isEmpty) {
      return;
    }

    final viewModel = Provider.of<FundraiserApplicationViewModel>(
      context,
      listen: false,
    );

    final result = await viewModel.rejectApplication(
      applicationId,
      _rejectionReasonController.text.trim(),
    );

    Navigator.of(context).pop();
    _rejectionReasonController.clear();

    if (result == null) {
      Constants.showSuccessMessage(context, 'Заявку відхилено');
    } else {
      Constants.showErrorMessage(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ProfileViewModel(viewingUserId: widget.userId)..fetchUserProfile(),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          final bool isOwner =
              widget.userId == null ||
              widget.userId == viewModel.currentAuthUserId;
          final bool isVolunteerViewingOrganization =
              viewModel.currentAuthUserId != null &&
              viewModel.user?.role == UserRole.organization &&
              viewModel.viewingUserId != null &&
              viewModel.viewingUserId != viewModel.currentAuthUserId;

          if (viewModel.user != null &&
              viewModel.user!.role != UserRole.organization) {
            Navigator.of(context).pushNamed(AppRoutes.volunteerProfileScreen);
          }
          final OrganizationModel? organization =
              viewModel.user is OrganizationModel
              ? viewModel.user as OrganizationModel
              : null;
          return Scaffold(
            backgroundColor: appThemeColors.blueAccent,
            appBar: AppBar(
              backgroundColor: appThemeColors.appBarBg,
              leading: IconButton(
                onPressed: () {
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
                    isOwner ? 'Мій профіль' : 'Профіль',
                    style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                    ),
                  ),
                  if (isOwner)
                    IconButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pushNamed(AppRoutes.settingsScreen);
                      },
                      icon: Icon(
                        Icons.settings,
                        size: 32,
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                ],
              ),
            ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: const Alignment(0.9, -0.4),
                  end: const Alignment(-0.9, 0.4),
                  colors: [
                    appThemeColors.blueAccent,
                    appThemeColors.cyanAccent,
                  ],
                ),
              ),
              child: viewModel.isLoading && viewModel.user == null
                  ? Center(
                      child: CircularProgressIndicator(
                        color: appThemeColors.primaryWhite,
                      ),
                    )
                  : viewModel.user == null
                  ? Center(
                      child: Text(
                        'Профіль фонду не знайдено або стався збій',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //Блок інформації про користувача (шапка)
                          _buildProfileSection(
                            organization!,
                            isOwner,
                            viewModel,
                          ),
                          if (organization.isVerification != null &&
                              !organization.isVerification!)
                            _buildVerificationStatus(viewModel),
                          if (viewModel.currentUserRole !=
                                  UserRole.organization &&
                              viewModel.isFollowing != null &&
                              !isOwner)
                            _buildFollowSection(
                              context,
                              viewModel,
                              organization,
                            ),
                          _buildStatistics(organization, viewModel),
                          if (organization.aboutMe != null)
                            _buildBio(organization),
                          _buildContactInfo(context, organization),
                          if (organization.trustBadges != null)
                            _buildOrganizationStatusBadges(organization),
                          _buildEditProfileButton(context, viewModel, isOwner),
                          if (organization.categoryChips != null)
                            _buildBadge(organization),
                          if (isOwner && organization.isVerification == true)
                            _buildCreateNewCollectionButton(viewModel),
                          _buildActiveCollectionsSection(viewModel, isOwner),
                          _buildRecentActivityScreen(viewModel),
                          if (viewModel.latestActivities.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                'Немає останніх активностей.',
                                style: TextStyleHelper.instance.title16Regular
                                    .copyWith(
                                      color: appThemeColors.backgroundLightGrey,
                                    ),
                              ),
                            )
                          else
                            LatestActivities(
                              isOwner: isOwner,
                              displayItems: viewModel.latestActivities
                                  .take(3)
                                  .toList(),
                              currentAuthId: viewModel.currentAuthUserId!,
                            ),
                          if (isOwner)
                            _buildApplicationsSection(viewModel, context),
                          SizedBox(height: 70),
                        ],
                      ),
                    ),
            ),
            floatingActionButton: isVolunteerViewingOrganization
                ? FloatingActionButton.extended(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.createFundraisingApplicationScreen,
                        arguments: organization?.uid!,
                      );
                    },
                    label: Text(
                      'Подати заявку на збір',
                      style: TextStyleHelper.instance.title16Bold.copyWith(
                        color: appThemeColors.primaryWhite,
                      ),
                    ),
                    icon: Icon(
                      Icons.add_task,
                      color: appThemeColors.primaryWhite,
                    ),
                    backgroundColor: appThemeColors.successGreen,
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(
    OrganizationModel user,
    bool isOwner,
    ProfileViewModel viewModel,
  ) {
    final String displayName = user.organizationName ?? 'Благодійний фонд';
    final String displayCity = user.city != null && user.city!.isNotEmpty
        ? 'м. ${user.city}'
        : 'Місто не вказано';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 7),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: appThemeColors.lightGreenColor,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : null,
                child: user.photoUrl == null
                    ? Icon(
                        Icons.business,
                        size: 60,
                        color: appThemeColors.primaryWhite,
                      )
                    : null,
              ),
              if (isOwner)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CustomImageView(
                    imagePath: ImageConstant.penIcon,
                    height: 32,
                    width: 32,
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (image != null) {
                        await viewModel.updateProfilePhoto(File(image.path));
                      }
                    },
                  ),
                ),
            ],
          ),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.placeholderIcon,
                      height: 16,
                      width: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      displayCity,
                      style: TextStyleHelper.instance.title16Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatus(ProfileViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.orangeLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Верифікація в процесі',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryWhite,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Документи розглядаються адміністратором. Очікування розгляду до 24 годин',
            style: TextStyleHelper.instance.title13Regular.copyWith(
              color: appThemeColors.primaryWhite,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatistics(OrganizationModel user, ProfileViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 38, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          StatisticItemWidget(value: user.fundraisingsCount, label: 'зборів'),
          StatisticItemWidget(value: user.projectsCount, label: 'проєктів'),
          StatisticItemWidget(value: user.eventsCount, label: 'подій'),
          StatisticItemWidget(
            value: viewModel.followersCount,
            label: 'підписників',
          ),
        ],
      ),
    );
  }

  Widget _buildBio(OrganizationModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Про фонд',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          Text(
            user.aboutMe ?? '',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
              height: 1.2,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, OrganizationModel user) {
    bool hasContactInfo =
        (user.email != null && user.email!.isNotEmpty) ||
        (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ||
        (user.telegramLink != null && user.telegramLink!.isNotEmpty) ||
        (user.instagramLink != null && user.instagramLink!.isNotEmpty);
    if (!hasContactInfo) {
      return const SizedBox.shrink(); // Не відображати секцію, якщо немає даних
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Контактна інформація',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          if (user.website != null && user.website!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () async {
                  String link = user.website!;
                  final Uri websiteUri = Uri.parse(link);
                  if (await canLaunchUrl(websiteUri)) {
                    await launchUrl(websiteUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Неможливо відкрити посилання.')),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.link,
                      size: 20,
                      color: appThemeColors.backgroundLightGrey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user.website!,
                      style: TextStyleHelper.instance.title16Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                        decoration: TextDecoration.underline,
                        decorationColor: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (user.email != null && user.email!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.email,
                    color: appThemeColors.backgroundLightGrey,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    user.email!,
                    style: TextStyleHelper.instance.title16Regular.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                    ),
                  ),
                ],
              ),
            ),
          if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () async {
                  final Uri phoneUri = Uri(
                    scheme: 'tel',
                    path: user.phoneNumber!,
                  );
                  if (await canLaunchUrl(phoneUri)) {
                    await launchUrl(phoneUri);
                  } else {
                    // Обробка помилки, якщо неможливо зателефонувати
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Неможливо відкрити додаток для дзвінків.',
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.phone,
                      color: appThemeColors.backgroundLightGrey,
                      size: 20,
                    ), // Приклад іконки
                    const SizedBox(width: 12),
                    Text(
                      user.phoneNumber!,
                      style: TextStyleHelper.instance.title16Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                        decoration: TextDecoration.underline,
                        // Для підкреслення, що це посилання
                        decorationColor: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (user.telegramLink != null && user.telegramLink!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () async {
                  String link = user.telegramLink!;
                  if (!link.startsWith('http')) {
                    link = 'https://t.me/${link.replaceAll('@', '')}';
                  }
                  final Uri telegramUri = Uri.parse(link);
                  if (await canLaunchUrl(telegramUri)) {
                    await launchUrl(telegramUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Неможливо відкрити посилання на Telegram.',
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.telegram,
                      size: 20,
                      color: appThemeColors.backgroundLightGrey,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      user.telegramLink!,
                      style: TextStyleHelper.instance.title16Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                        decoration: TextDecoration.underline,
                        decorationColor: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (user.instagramLink != null && user.instagramLink!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: GestureDetector(
                onTap: () async {
                  String link = user.instagramLink!;
                  if (!link.startsWith('http')) {
                    link =
                        'https://instagram.com/${link.replaceAll('@', '')}'; // Форматуємо для Instagram
                  }
                  final Uri instagramUri = Uri.parse(link);
                  if (await canLaunchUrl(instagramUri)) {
                    await launchUrl(instagramUri);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Неможливо відкрити посилання на Instagram.',
                        ),
                      ),
                    );
                  }
                },
                child: Row(
                  children: [
                    CustomImageView(
                      imagePath: ImageConstant.instagramIcon,
                      height: 20,
                      width: 20,
                      color: appThemeColors.backgroundLightGrey,
                    ),
                    // Приклад іконки
                    const SizedBox(width: 12),
                    Text(
                      user.instagramLink!,
                      style: TextStyleHelper.instance.title16Regular.copyWith(
                        color: appThemeColors.backgroundLightGrey,
                        decoration: TextDecoration.underline,
                        decorationColor: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrganizationStatusBadges(OrganizationModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Знаки довіри',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.trustBadges!
                .map((badge) => TrustBadgeWidget(badge: badge))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(
    BuildContext context,
    ProfileViewModel viewModel,
    bool isOwner,
  ) {
    if (isOwner) {
      return Container(
        margin: EdgeInsets.symmetric(horizontal: 28, vertical: 7),
        child: CustomElevatedButton(
          text: 'Редагувати профіль',
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamed(AppRoutes.editUserProfileScreen).then((_) {
              viewModel.fetchUserProfile();
            });
          },
          width: double.infinity,
          height: 44,
          borderRadius: 24,
          textStyle: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      );
    }
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28, vertical: 7),
      child: CustomElevatedButton(
        text: 'Написати',
        onPressed: () async {
          final friendHelper = FriendService();
          String? chatId = await friendHelper.getOrCreateFriendChat(
            viewModel.currentAuthUserId!,
            viewModel.user!.uid!,
          );
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.chatFriendScreen, arguments: chatId);
        },
        width: double.infinity,
        height: 44,
        borderRadius: 24,
        textStyle: TextStyleHelper.instance.title16Regular.copyWith(
          color: appThemeColors.backgroundLightGrey,
        ),
      ),
    );
  }

  Widget _buildBadge(OrganizationModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сфери діяльності',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          SizedBox(height: 7),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.categoryChips!
                .map((chip) => CategoryChipWidget(chip: chip))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateNewCollectionButton(ProfileViewModel viewModel) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: CustomElevatedButton(
        text: 'Створити новий збір',
        onPressed: () {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.createFundraisingScreen, arguments: '');
        },
        width: double.infinity,
        height: 50,
        borderRadius: 28,
        backgroundColor: appThemeColors.backgroundLightGrey,
        textStyle: TextStyleHelper.instance.title16Regular,
        leftIcon: Icon(Icons.add, color: appThemeColors.blueAccent),
        borderColor: appThemeColors.blueAccent,
      ),
    );
  }

  Widget _buildActiveCollectionsSection(
    ProfileViewModel viewModel,
    bool isOwner,
  ) {
    final savedFundraisers = viewModel.activeFundraisings;
    final displayItems = savedFundraisers.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Активні збори',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
              if (savedFundraisers.length > 3)
                GestureDetector(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.allSavedFundraisersScreen);
                  },
                  child: Text(
                    'Переглянути всі',
                    style: TextStyleHelper.instance.title16Regular.copyWith(
                      color: appThemeColors.lightGreenColor,
                      decoration: TextDecoration.underline,
                      decorationColor: appThemeColors.lightGreenColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Відображення списку або повідомлення, якщо список порожній
        if (savedFundraisers.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'У вас немає активних зборів.',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final fundraising = displayItems[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: ActiveFundraisingItem(
                  fundraising: fundraising,
                  isOwner: isOwner,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildRecentActivityScreen(ProfileViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Остання активність',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.allActivitiesScreen);
            },
            child: Text(
              'Всі дії',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.lightGreenColor,
                decoration: TextDecoration.underline,
                decorationColor: appThemeColors.lightGreenColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsSection(
    ProfileViewModel viewModel,
    BuildContext context,
  ) {
    // Витягуємо перші 3 заявки на збори
    final applications = viewModel.organizationFundraiserApplications
        .take(3)
        .toList();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Заявки на збори',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
              if (viewModel.organizationFundraiserApplications.length > 3)
                GestureDetector(
                  onTap: () {
                    Navigator.of(
                      context,
                    ).pushNamed(AppRoutes.allFundraiserApplicationsScreen);
                  },
                  child: Text(
                    'Переглянути всі',
                    style: TextStyleHelper.instance.title16Regular.copyWith(
                      color: appThemeColors.lightGreenColor,
                      decoration: TextDecoration.underline,
                      decorationColor: appThemeColors.lightGreenColor,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (applications.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Вам ще не подали заявок на збори.',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ),
        if (applications.isNotEmpty)
          ...applications.map((app) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: FundraiserApplicationItemOrg(
                application: app,
                onApprove: (String applicationId) async {
                  final viewModel = Provider.of<FundraiserApplicationViewModel>(
                    context,
                    listen: false,
                  );
                  final result = await viewModel.approveApplication(
                    applicationId,
                  );
                  if (result == null) {
                    Constants.showSuccessMessage(context, 'Заявку схвалено!');
                  } else {
                    Constants.showErrorMessage(context, result);
                  }
                },
                onReject: (String applicationId) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Відхилити заявку',
                          style: TextStyleHelper.instance.title18Bold,
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Вкажіть причину відхилення заявки:',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(color: appThemeColors.primaryBlack),
                            ),
                            const SizedBox(height: 16),
                            CustomTextField(
                              controller: _rejectionReasonController,
                              label: 'Причина відхилення',
                              hintText: 'Наприклад: Недостатньо документів...',
                              maxLines: 3,
                              inputType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Будь ласка, вкажіть причину відхилення';
                                }
                                return null;
                              },
                              height: 48,
                              labelColor: appThemeColors.primaryBlack,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              _rejectionReasonController.clear();
                              Navigator.of(context).pop();
                            },
                            child: Text(
                              'Скасувати',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: appThemeColors.textMediumGrey,
                                  ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () =>
                                _rejectApplication(applicationId, context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appThemeColors.errorRed,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Відхилити',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                applicantUser: viewModel.fetchUser(app.volunteerId),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildFollowSection(
    BuildContext context,
    ProfileViewModel viewModel,
    OrganizationModel organization,
  ) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              viewModel.toggleFollow(organization.uid!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: viewModel.isFollowing!
                  ? appThemeColors.textMediumGrey
                  : appThemeColors.successGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              viewModel.isFollowing! ? 'Відписатись' : 'Підписатись',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
