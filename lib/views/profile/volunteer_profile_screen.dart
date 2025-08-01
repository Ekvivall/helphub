import 'dart:io';

import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/models/achievement_item_model.dart';
import 'package:helphub/models/medal_item_model.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:helphub/widgets/profile/achievement_item.dart';
import 'package:helphub/widgets/profile/statistic_item_widget.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/utils/constants.dart';
import '../../models/activity_model.dart';
import '../../models/friend_request_model.dart';
import '../../models/volunteer_model.dart';
import '../../routes/app_router.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/profile/category_chip_widget.dart';
import '../../widgets/profile/event_organization_activity_item.dart';
import '../../widgets/profile/event_participation_activity_item.dart';
import '../../widgets/profile/medal_item.dart';
import '../../widgets/user_avatar_with_frame.dart';

class VolunteerProfileScreen extends StatelessWidget {
  VolunteerProfileScreen({super.key, this.userId});

  final String? userId; //ID користувача, чий профіль переглядаємо
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) =>
          ProfileViewModel(viewingUserId: userId)..fetchUserProfile(),
      child: Consumer<ProfileViewModel>(
        builder: (context, viewModel, child) {
          final bool isOwner =
              userId == null || userId == viewModel.currentAuthUserId;

          if (viewModel.user != null &&
              viewModel.user!.role != UserRole.volunteer) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                Navigator.of(
                  context,
                ).pushReplacementNamed(AppRoutes.organizationProfileScreen);
              }
            });
          }
          final VolunteerModel? volunteer = viewModel.user is VolunteerModel
              ? viewModel.user as VolunteerModel
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
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      isOwner ? Icons.settings : Icons.more_vert,
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
                        'Профіль не знайдено або стався збій',
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
                          _buildProfileSection(volunteer!, isOwner, viewModel),
                          _buildLevelCard(volunteer, isOwner),
                          _buildStatistics(volunteer),
                          if (volunteer.aboutMe != null) _buildBio(volunteer),
                          _buildContactInfo(context, volunteer),
                          if (volunteer.categoryChips != null)
                            _buildBadge(volunteer),
                          _buildEditProfileButton(context, viewModel),
                          if (volunteer.achievements != null)
                            _buildAchievementsSection(volunteer),
                          if (volunteer.achievements != null)
                            _buildAchievementsList(volunteer),
                          if (volunteer.medals != null)
                            _buildMedalsSection(viewModel),
                          if (volunteer.medals != null)
                            _buildMedalsList(volunteer),
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
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: viewModel.latestActivities.length,
                              padding: const EdgeInsets.all(12),
                              itemBuilder: (context, index) {
                                final activity =
                                    viewModel.latestActivities[index];
                                switch (activity.type) {
                                  case ActivityType.eventParticipation:
                                    return EventParticipationActivityItem(
                                      activity: activity,
                                    );
                                  // TODO: Додати інші типи активностей тут
                                  case ActivityType.eventOrganization:
                                    return EventOrganizationActivityItem(
                                      activity: activity,
                                    );
                                  case ActivityType.projectTaskCompletion:
                                    return Text(
                                      'Виконано завдання в проекті: ${activity.title}',
                                      style: TextStyleHelper
                                          .instance
                                          .title16Regular
                                          .copyWith(
                                            color: appThemeColors
                                                .backgroundLightGrey,
                                          ),
                                    );
                                  case ActivityType.projectNewApplication:
                                    return Text(
                                      'Нова заявка на проект: ${activity.title}',
                                      style: TextStyleHelper
                                          .instance
                                          .title16Regular
                                          .copyWith(
                                            color: appThemeColors
                                                .backgroundLightGrey,
                                          ),
                                    );
                                  case ActivityType.fundraiserCreation:
                                    return Text(
                                      'Створено збір коштів: ${activity.title}',
                                      style: TextStyleHelper
                                          .instance
                                          .title16Regular
                                          .copyWith(
                                            color: appThemeColors
                                                .backgroundLightGrey,
                                          ),
                                    );
                                  }
                              },
                            ),
                          if (isOwner) ...[
                            _buildSavedFees(viewModel),
                            _buildProjectApplications(viewModel),
                            _buildFollowedOrganizationsSection(
                              context,
                              viewModel,
                            ),
                            _buildMyFriends(context, viewModel),
                            _buildFriendList(context, viewModel),
                            _buildFooterMyFriends(context, viewModel),
                          ],
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileSection(
    VolunteerModel user,
    bool isOwner,
    ProfileViewModel viewModel,
  ) {
    final String displayName = user.fullName ?? user.displayName ?? 'Волонтер';
    final String displayCity = user.city != null && user.city!.isNotEmpty
        ? 'м. ${user.city}'
        : 'Місто не вказано';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 36, vertical: 7),
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
                        Icons.person,
                        size: 60,
                        color: appThemeColors.primaryWhite,
                      )
                    : null,
              ),
              if (user.frame != null && user.frame!.isNotEmpty)
                CustomImageView(
                  imagePath: user.frame!,
                  height: 130,
                  width: 130,
                  fit: BoxFit.contain,
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

  Widget _buildLevelCard(VolunteerModel user, bool isOwner) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 28, vertical: 7),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.blueMixedColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            user.levelTitle ?? '',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          if (isOwner) SizedBox(height: 4),
          if (isOwner)
            Text(
              '(${user.levelProgress}/9 рівень)',
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
          SizedBox(height: 8),
          Text(
            '"${user.levelDescription}"',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              fontStyle: FontStyle.italic,
              color: appThemeColors.primaryBlack,
            ),
            textAlign: TextAlign.center,
          ),
          if (isOwner) SizedBox(height: 16),
          if (isOwner)
            Container(
              width: double.infinity,
              height: 8,
              decoration: BoxDecoration(
                color: appThemeColors.backgroundLightGrey,
                borderRadius: BorderRadius.circular(4),
              ),

              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appThemeColors.backgroundLightGrey,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Container(
                    width: user.progressPercent ?? 0 / 100 * 200,
                    height: 8,
                    decoration: BoxDecoration(
                      color: appThemeColors.successGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          if (isOwner) SizedBox(height: 12),
          if (isOwner)
            Text(
              '${user.pointsToNextLevel} балів до наступного рівня',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildStatistics(VolunteerModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 48, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StatisticItemWidget(value: user.projectsCount, label: 'проєктів'),
          SizedBox(width: 48),
          StatisticItemWidget(value: user.eventsCount, label: 'подій'),
        ],
      ),
    );
  }

  Widget _buildBio(VolunteerModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Про мене',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          Text(
            user.aboutMe ?? '',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
              height: 1.2,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Widget _buildEditProfileButton(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final FriendshipStatus status = viewModel.friendshipStatus;

    switch (status) {
      case FriendshipStatus.self:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
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
      case FriendshipStatus.notFriends:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
          child: CustomElevatedButton(
            text: 'Додати в друзі',
            onPressed: () => viewModel.sendFriendRequest(userId!),
            width: double.infinity,
            height: 44,
            borderRadius: 24,
            textStyle: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
            backgroundColor: appThemeColors.successGreen,
          ),
        );
      case FriendshipStatus.requestSent:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
          child: CustomElevatedButton(
            text: 'Запит відправлено',
            onPressed: null,
            // Disabled button
            width: double.infinity,
            height: 44,
            borderRadius: 24,
            backgroundColor: appThemeColors.blueTransparent,
            textStyle: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey.withAlpha(179),
            ),
          ),
        );
      case FriendshipStatus.requestReceived:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  text: 'Прийняти',
                  onPressed: () =>
                      viewModel.acceptFriendRequestFromUser(userId!),
                  height: 44,
                  borderRadius: 24,
                  textStyle: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomElevatedButton(
                  text: 'Відхилити',
                  onPressed: () =>
                      viewModel.rejectFriendRequestFromUser(userId!),
                  height: 44,
                  borderRadius: 24,
                  backgroundColor: appThemeColors.blueTransparent,
                  textStyle: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
              ),
            ],
          ),
        );
      case FriendshipStatus.friends:
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
          child: Row(
            children: [
              Expanded(
                child: CustomElevatedButton(
                  text: 'Написати',
                  onPressed: () {
                    // TODO: Implement navigation to chat screen
                  },
                  height: 44,
                  borderRadius: 24,
                  backgroundColor: appThemeColors.blueTransparent,
                  textStyle: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: CustomElevatedButton(
                  text: 'Видалити з друзів',
                  onPressed: () {
                    Constants.showConfirmationDialog(
                      context,
                      'Підтвердження видалення',
                      'Ви впевнені, що хочете видалити цього користувача зі своїх друзів?',
                      'Видалити',
                      viewModel,
                      userId!,
                    );
                  },
                  height: 44,
                  borderRadius: 24,
                  backgroundColor: appThemeColors.errorRed.withAlpha(120),
                  textStyle: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildBadge(VolunteerModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Сфери інтересів',
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

  Widget _buildAchievementsSection(VolunteerModel user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Досягнення',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          Text(
            '${user.achievementsCount}/12',
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Всі досягнення',
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

  Widget _buildAchievementsList(VolunteerModel user) {
    List<AchievementItemModel> achievements = user.achievements!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 7),
      child: Wrap(
        spacing: 16,
        runSpacing: 16,
        children: achievements
            .take(3)
            .map(
              (achievement) =>
                  AchievementItemWidget(achievementItemModel: achievement),
            )
            .toList(),
      ),
    );
  }

  Widget _buildMedalsSection(ProfileViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Медалі',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Text(
              'Всі медалі',
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

  Widget _buildMedalsList(VolunteerModel user) {
    List<MedalItemModel> medals = user.medals!;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: medals
            .map((medal) => MedalItemWidget(medalItemModel: medal))
            .toList(),
      ),
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
            onTap: () {},
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

  Widget _buildSavedFees(ProfileViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Збережені збори',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          GestureDetector(
            onTap: () {},
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
    );
  }

  Widget _buildProjectApplications(ProfileViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Заявки на проєкти',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          GestureDetector(
            onTap: () {},
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
    );
  }

  Widget _buildMyFriends(BuildContext context, ProfileViewModel viewModel) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Мої друзі',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          if (viewModel.friendProfiles.length > 3)
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushNamed(AppRoutes.friendsListScreen);
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
    );
  }

  Widget _buildFriendList(BuildContext context, ProfileViewModel viewModel) {
    final int friendsToShow = viewModel.friendProfiles.length > 3
        ? 3
        : viewModel.friendProfiles.length;
    if (friendsToShow == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: List.generate(friendsToShow, (index) {
          final friend = viewModel.friendProfiles[index];
          return Card(
            color: appThemeColors.backgroundLightGrey,
            margin: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              // Дозволяє натискати на картку
              onTap: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.volunteerProfileScreen,
                  arguments: friend.uid,
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    UserAvatarWithFrame(
                      size: 20,
                      role: UserRole.volunteer,
                      photoUrl: friend.photoUrl,
                      frame: friend.frame,
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            friend.fullName ??
                                friend.displayName ??
                                'Невідомий користувач',
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  color: appThemeColors.primaryBlack,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          if (friend.city != null && friend.city!.isNotEmpty)
                            Text(
                              'м. ${friend.city!}',
                              style: TextStyleHelper.instance.title13Regular
                                  .copyWith(
                                    color: appThemeColors.textMediumGrey,
                                  ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFooterMyFriends(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final int requestCount = viewModel.incomingFriendRequestsCount;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.findFriendsScreen);
            },
            child: Text(
              'Знайти і додати друга',
              style: TextStyleHelper.instance.title16Regular.copyWith(
                color: appThemeColors.lightGreenColor,
                decoration: TextDecoration.underline,
                decorationColor: appThemeColors.lightGreenColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushNamed(AppRoutes.friendRequestsScreen);
            },
            child: Row(
              children: [
                Text(
                  'Заявки в друзі',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.lightGreenColor,
                    decoration: TextDecoration.underline,
                    decorationColor: appThemeColors.lightGreenColor,
                  ),
                ),
                if (requestCount > 0) ...[
                  SizedBox(width: 7),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: appThemeColors.lightGreenColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$requestCount',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(BuildContext context, VolunteerModel user) {
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

  Widget _buildFollowedOrganizationsSection(
    BuildContext context,
    ProfileViewModel viewModel,
  ) {
    final int organizationsToShow = viewModel.followedOrganizations.length > 2
        ? 2
        : viewModel.followedOrganizations.length;
    if (organizationsToShow == 0) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Підписані фонди',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
              if (viewModel.followedOrganizations.length > organizationsToShow)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: CustomElevatedButton(
                    text: 'Показати всі підписки',
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.allFollowedOrganizationsScreen);
                    },
                    backgroundColor: appThemeColors.lightGreenColor,
                    borderRadius: 8,
                    textStyle: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryWhite,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 1.0,
            ),
            itemCount: organizationsToShow,
            // Use limited count here
            itemBuilder: (context, index) {
              final organization = viewModel.followedOrganizations[index];
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.organizationProfileScreen,
                    arguments: organization.uid,
                  );
                },
                child: Card(
                  color: appThemeColors.blueTransparent,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: appThemeColors.transparent,
                        backgroundImage: organization.photoUrl != null
                            ? NetworkImage(organization.photoUrl!)
                            : null,
                        child: organization.photoUrl == null
                            ? Icon(
                                Icons.business,
                                size: 80,
                                color: appThemeColors.primaryWhite,
                              )
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          organization.organizationName ?? 'Невідомий Фонд',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyleHelper.instance.title16Bold.copyWith(
                            color: appThemeColors.primaryWhite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
