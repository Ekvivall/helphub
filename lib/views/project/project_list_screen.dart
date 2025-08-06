import 'package:flutter/material.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/views/project/project_filters_screen.dart';
import 'package:provider/provider.dart';

import '../../core/utils/image_constant.dart';
import '../../models/base_profile_model.dart';
import '../../models/volunteer_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../view_models/project/project_view_model.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/custom_image_view.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/custom_notification_icon_button.dart';
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
    return Scaffold(
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
        child: Consumer<ProjectViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.user == null) return SizedBox.shrink();
            final BaseProfileModel user = viewModel.user!;
            return Column(
              children: [
                _buildHeader(context, viewModel, user),
                const SizedBox(height: 16),
                Expanded(child: _buildProjectList(viewModel)),
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
          const SizedBox(width: 7),
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
          IconButton(
            onPressed: () {
              //TODO
            },
            icon: CustomImageView(
              imagePath: ImageConstant.tournamentIcon,
              height: 24,
              width: 24,
            ),
          ),
          CustomNotificationIconButton(),
        ],
      ),
    );
  }

  Widget _buildProjectList(ProjectViewModel viewModel) {
    final String? errorMessage = viewModel.errorMessage;
    final List<dynamic> filteredProjects = viewModel.filteredProjects;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.successGreen),
      );
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            errorMessage,
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.errorRed,
            ),
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
        );
      },
    );
  }
}
