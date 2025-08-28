import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/friend_service.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/profile/profile_view_model.dart';
import '../../widgets/custom_input_field.dart';

class AllFollowedOrganizationsScreen extends StatefulWidget {
  const AllFollowedOrganizationsScreen({super.key});

  @override
  State<AllFollowedOrganizationsScreen> createState() => _AllFollowedOrganizationsScreenState();
}

class _AllFollowedOrganizationsScreenState extends State<AllFollowedOrganizationsScreen>{
  final TextEditingController _searchController = TextEditingController();
  late ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ProfileViewModel>(context, listen: false);
    _searchController.addListener(_onSearchChanged);
    _viewModel.searchFollowedOrganizations('');
  }

  void _onSearchChanged() {
    _viewModel.searchFollowedOrganizations(_searchController.text);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
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
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Усі підписані фонди',
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
            begin: Alignment(0.9, -0.4),
            end: Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Column(
            children: [
        Padding(
        padding: const EdgeInsets.all(16),
        child: CustomInputField(
          controller: _searchController,
          hintText: 'Пошук фондів...',
          prefixIcon: Icon(
            Icons.search,
            color: appThemeColors.textMediumGrey,
          ),
          borderRadius: 24,
        ),
      ),
      Expanded(
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.filteredFollowedProfiles.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (viewModel.filteredFollowedProfiles.isEmpty&&
                _searchController.text.isEmpty) {
              return Center(
                child: Text(
                  'Ви ще не підписані на жоден фонд.',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }if (viewModel.filteredFollowedProfiles.isEmpty &&
                _searchController.text.isNotEmpty) {
              return Center(
                child: Text(
                  'Фондів за запитом "${_searchController.text}" не знайдено',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.builder(
              itemCount: viewModel.filteredFollowedProfiles.length,
              itemBuilder: (context, index) {
                final organization = viewModel.filteredFollowedProfiles[index];
                return Card(
                  color: appThemeColors.backgroundLightGrey,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: InkWell(
                    // Дозволяє натискати на картку
                    onTap: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.organizationProfileScreen,
                        arguments: organization.uid,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: appThemeColors.lightGreenColor,
                            backgroundImage: organization.photoUrl != null
                                ? NetworkImage(organization.photoUrl!)
                                : null,
                            child: organization.photoUrl == null
                                ? Icon(
                                    Icons.business,
                                    size: 60,
                                    color: appThemeColors.primaryWhite,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  organization.organizationName ??
                                      'Невідомий фонд',
                                  style: TextStyleHelper
                                      .instance
                                      .title16Bold
                                      .copyWith(
                                        color: appThemeColors.primaryBlack,
                                      ),
                                ),
                                if (organization.city != null &&
                                    organization.city!.isNotEmpty)
                                  Text(
                                    'м. ${organization.city??'Невідомо'}',
                                    style: TextStyleHelper
                                        .instance
                                        .title14Regular
                                        .copyWith(
                                          color: appThemeColors.textMediumGrey,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              final friendHelper = FriendService();
                              String? chatId = await friendHelper.getOrCreateFriendChat(
                                viewModel.currentAuthUserId!,
                                viewModel.user!.uid!,
                              );
                              Navigator.of(context).pushNamed(
                                AppRoutes.chatFriendScreen,
                                arguments: chatId,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appThemeColors.blueTransparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                            ),
                            child: Text(
                              'Написати',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(color: appThemeColors.primaryBlack),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ])));
  }
}
