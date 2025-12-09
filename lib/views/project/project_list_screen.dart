import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/views/project/project_filters_screen.dart';
import 'package:provider/provider.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/models/volunteer_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../view_models/profile/profile_view_model.dart';
import '../../view_models/project/project_view_model.dart';
import '../../widgets/custom_admin_icon_button.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/custom_notification_icon_button.dart';
import '../../widgets/custom_tournament_icon_button.dart';
import '../../widgets/project/project_list_item.dart';
import '../../widgets/user_avatar_with_frame.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: appThemeColors.blueAccent,
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
          child: Consumer2<ProjectViewModel, ProfileViewModel>(
            builder: (context, viewModel, profileViewModel, child) {
              if (profileViewModel.user == null) return SizedBox.shrink();
              final BaseProfileModel user = profileViewModel.user!;
              return Column(
                children: [
                  _buildHeader(context, viewModel, user),
                  const SizedBox(height: 16),
                  Expanded(child: _buildProjectList(viewModel, profileViewModel)),
                ],
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pushNamed(AppRoutes.createProjectScreen, arguments: '');
          },
          backgroundColor: appThemeColors.blueAccent,
          shape: const CircleBorder(),
          child: Icon(Icons.add, color: appThemeColors.primaryWhite, size: 37),
        ),
        bottomNavigationBar: buildBottomNavigationBar(
          context,
          1, // Index 1 for "Проєкти"
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ProjectViewModel viewModel,
    BaseProfileModel user,
  ) {
    final VolunteerModel? volunteer = user is VolunteerModel ? user : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      color: appThemeColors.appBarBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWithFrame(
            size: 22,
            role: user.role,
            photoUrl: user.photoUrl,
            frame: volunteer?.frame,
            uid: user.uid!,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: CustomInputField(
              hintText: 'Пошук проєктів...',
              controller: _searchController,
              onChanged: (query) {
                viewModel.setSearchQuery(query);
              },
              borderRadius: 10,
              textColor: appThemeColors.primaryBlack,
              hintTextColor: appThemeColors.textMediumGrey,
              borderColor: appThemeColors.transparent,
              focusedBorderColor: appThemeColors.blueAccent,
              suffixIcon: IconButton(
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return const ProjectFiltersBottomSheet();
                    },
                  );
                },
                icon: Icon(
                  Icons.filter_list_alt,
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ),
          ),
          if (user.role == UserRole.volunteer) CustomTournamentIconButton(),
          if (user.role == UserRole.admin) CustomAdminIconButton(),
          CustomNotificationIconButton(),
        ],
      ),
    );
  }

  Widget _buildProjectList(ProjectViewModel viewModel, ProfileViewModel profileViewModel) {
    final String? errorMessage = viewModel.errorMessage;
    final List<dynamic> filteredProjects = viewModel.filteredProjects;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.successGreen),
      );
    }
    if (errorMessage != null) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: appThemeColors.primaryWhite.withAlpha(230),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: appThemeColors.errorRed.withAlpha(127)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: appThemeColors.errorRed,
              ),
              const SizedBox(height: 16),
              Text(
                'Помилка завантаження',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: viewModel.refresh,
                style: ElevatedButton.styleFrom(
                  backgroundColor: appThemeColors.lightGreenColor,
                ),
                child: Text(
                  'Спробувати знову',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (filteredProjects.isEmpty) {
      return Center(
        child: Text(
          'Проєктів не знайдено або вони не відповідають критеріям фільтрації.',
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredProjects.length,
      itemBuilder: (context, index) {
        final project = filteredProjects[index];
        return ProjectListItem(
          project: project,
          viewModel: viewModel,
          userCurrentLocation: viewModel.currentUserLocation,
          currentUserId: profileViewModel.user!.uid!,
        );
      },
    );
  }
}
