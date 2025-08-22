import 'package:flutter/material.dart';
import 'package:helphub/models/organization_model.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:provider/provider.dart';

import '../../models/base_profile_model.dart';
import '../../models/volunteer_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../view_models/fundraising/fundraising_view_model.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/custom_notification_icon_button.dart';
import '../../widgets/custom_tournament_icon_button.dart';
import '../../widgets/fundraising/fundraising_list_item.dart';
import '../../widgets/user_avatar_with_frame.dart';
import 'fundraising_filters_bottom_sheet.dart';

class FundraisingListScreen extends StatefulWidget {
  const FundraisingListScreen({super.key});

  @override
  State<FundraisingListScreen> createState() => _FundraisingListScreenState();
}

class _FundraisingListScreenState extends State<FundraisingListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FundraisingViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.user == null) {
          return Scaffold(
            backgroundColor: appThemeColors.blueAccent,
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(0.9, -0.4),
                  end: Alignment(-0.9, 0.4),
                  colors: [
                    appThemeColors.blueAccent,
                    appThemeColors.cyanAccent,
                  ],
                ),
              ),
            ),
          );
        }
        final BaseProfileModel user = viewModel.user!;
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
            child: Column(
              children: [
                _buildHeader(context, viewModel, user),
                const SizedBox(height: 16),
                Expanded(child: _buildFundraisingList(viewModel)),
                const SizedBox(height: 14),
              ],
            ),
          ),
          floatingActionButton:
              user is OrganizationModel && user.isVerification == true
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.createFundraisingScreen,
                      arguments: '',
                    );
                  },
                  backgroundColor: appThemeColors.blueAccent,
                  shape: const CircleBorder(),
                  child: Icon(
                    Icons.add,
                    color: appThemeColors.primaryWhite,
                    size: 37,
                  ),
                )
              : user is VolunteerModel
              ? FloatingActionButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(
                      AppRoutes.createFundraisingApplicationScreen,
                      arguments: '',
                    );
                  },
                  backgroundColor: appThemeColors.blueAccent,
                  shape: const CircleBorder(),
                  child: Icon(
                    Icons.request_quote,
                    color: appThemeColors.primaryWhite,
                    size: 37,
                  ),
                )
              : null,
          bottomNavigationBar: buildBottomNavigationBar(context, 2),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    FundraisingViewModel viewModel,
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
              hintText: 'Пошук зборів...',
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
                      return const FundraisingFiltersBottomSheet();
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
          CustomTournamentIconButton(),
          CustomNotificationIconButton(),
        ],
      ),
    );
  }

  Widget _buildFundraisingList(FundraisingViewModel viewModel) {
    final String? errorMessage = viewModel.errorMessage;
    final List<dynamic> filteredFundraisings = viewModel.filteredFundraisings;

    if (viewModel.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.successGreen),
      );
    }
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: appThemeColors.errorLight,
              ),
              const SizedBox(height: 16),
              Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.errorLight,
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (filteredFundraisings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volunteer_activism_outlined,
                size: 64,
                color: appThemeColors.backgroundLightGrey,
              ),
              const SizedBox(height: 16),
              Text(
                'Зборів не знайдено',
                textAlign: TextAlign.center,
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Спробуйте змінити критерії пошуку або очистити фільтри.',
                textAlign: TextAlign.center,
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey.withAlpha(177),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredFundraisings.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final fundraising = filteredFundraisings[index];
        return FundraisingListItem(
          fundraising: fundraising,
          viewModel: viewModel,
        );
      },
    );
  }
}
