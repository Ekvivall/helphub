import 'package:flutter/material.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/admin/admin_view_model.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:provider/provider.dart';

import '../../routes/app_router.dart';
import '../../widgets/custom_text_field.dart';

class AdminVolunteersScreen extends StatefulWidget {
  const AdminVolunteersScreen({super.key});

  @override
  State<AdminVolunteersScreen> createState() => _AdminVolunteersScreenState();
}

class _AdminVolunteersScreenState extends State<AdminVolunteersScreen> {
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
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Пошук волонтерів',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(0.9, -0.4),
            end: const Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Consumer<AdminViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: CustomTextField(
                    controller: _searchController,
                    label: 'Пошук',
                    hintText: "Введіть ім'я або місто...",
                    labelColor: appThemeColors.backgroundLightGrey,
                    inputType: TextInputType.text,
                    prefixIcon: Icon(
                      Icons.search,
                      color: appThemeColors.textMediumGrey,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: appThemeColors.textMediumGrey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.clearSearch();
                              setState(() {});
                            },
                          )
                        : null,
                    onChanged: (value) {
                      setState(() {});
                      if (value.trim().length >= 2) {
                        viewModel.searchVolunteers(value);
                      } else if (value.trim().isEmpty) {
                        viewModel.clearSearch();
                      }
                    },
                  ),
                ),
                // Результати пошуку
                Expanded(child: _buildSearchResults(viewModel)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchResults(AdminViewModel viewModel) {
    if (viewModel.isSearching) {
      return Center(
        child: CircularProgressIndicator(
          color: appThemeColors.backgroundLightGrey,
        ),
      );
    }

    if (viewModel.searchError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            viewModel.searchError!,
            textAlign: TextAlign.center,
            style: TextStyleHelper.instance.title16Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ),
      );
    }

    if (_searchController.text.trim().isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: appThemeColors.backgroundLightGrey.withAlpha(150),
            ),
            const SizedBox(height: 16),
            Text(
              'Введіть ім\'я або місто',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Почніть вводити для пошуку волонтерів',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.backgroundLightGrey.withAlpha(150),
              ),
            ),
          ],
        ),
      );
    }

    if (viewModel.searchResults.isEmpty) {
      return Center(
        child: Text(
          'Нічого не знайдено',
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: viewModel.searchResults.length,
      itemBuilder: (context, index) {
        final volunteer = viewModel.searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: appThemeColors.primaryWhite,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () {
              Navigator.of(context).pushNamed(
                AppRoutes.volunteerProfileScreen,
                arguments: volunteer.uid,
              );
            },
            leading: UserAvatarWithFrame(
              size: 24,
              role: UserRole.volunteer,
              uid: volunteer.uid,
              photoUrl: volunteer.photoUrl,
              frame: volunteer.frame,
            ),
            title: Text(
              volunteer.fullName ?? volunteer.displayName ?? 'Волонтер',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (volunteer.city != null)
                  Text(
                    'м. ${volunteer.city}',
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
                Text(
                  '${volunteer.points ?? 0} балів • ${volunteer.projectsCount ?? 0} проєктів',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: appThemeColors.textMediumGrey,
            ),
          ),
        );
      },
    );
  }
}
