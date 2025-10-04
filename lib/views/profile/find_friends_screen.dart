import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/data/models/friend_request_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/custom_input_field.dart';
import 'package:provider/provider.dart';

class FindFriendsScreen extends StatefulWidget {
  const FindFriendsScreen({super.key});

  @override
  State<FindFriendsScreen> createState() => _FindFriendsScreenState();
}

class _FindFriendsScreenState extends State<FindFriendsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late ProfileViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ProfileViewModel>(context, listen: false);
    _viewModel.clearSearchResults();
  }

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
          'Знайти друзів',
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
                hintText: 'Введіть нікнейм або ім\'я',
                prefixIcon: Icon(
                  Icons.search,
                  color: appThemeColors.textMediumGrey,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _viewModel.clearSearchResults();
                        },
                        icon: Icon(
                          Icons.clear,
                          color: appThemeColors.textMediumGrey,
                        ),
                      )
                    : null,
                borderRadius: 24,
                onChanged: (query) {
                  if (query.length >= 2) {
                    _viewModel.searchUsers(query);
                  } else if (query.isEmpty) {
                    _viewModel.clearSearchResults();
                  }
                },
              ),
            ),
            Expanded(
              child: Consumer<ProfileViewModel>(
                builder: (context, viewModel, child) {
                  if (viewModel.isSearching) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: appThemeColors.primaryWhite,
                      ),
                    );
                  }
                  if (viewModel.searchError != null) {
                    return Center(
                      child: Text(
                        viewModel.searchError!,
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (viewModel.searchResults.isEmpty &&
                      _searchController.text.isNotEmpty) {
                    return Center(
                      child: Text(
                        'Користувачів не знайдено',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (viewModel.searchResults.isEmpty &&
                      _searchController.text.isEmpty) {
                    return Center(
                      child: Text(
                        'Введіть нікнейм або повне ім\'я для пошуку.',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.primaryWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: viewModel.searchResults.length,
                    itemBuilder: (context, index) {
                      final user = viewModel.searchResults[index];
                      return Card(
                        color: appThemeColors.blueMixedColor,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: user.photoUrl != null
                                ? NetworkImage(user.photoUrl!)
                                : null,
                            backgroundColor: appThemeColors.blueAccent,
                            child: user.photoUrl == null
                                ? Icon(
                                    Icons.person,
                                    color: appThemeColors.backgroundLightGrey,
                                  )
                                : null,
                          ),
                          title: Text(
                            user.fullName ??
                                user.displayName ??
                                'Невідомий користувач',
                            style: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryBlack),
                          ),
                          subtitle: Text(
                            user.city != null ? 'м. ${user.city}' : '',
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(color: appThemeColors.textMediumGrey),
                          ),
                          trailing: _buildAddFriendButton(user, viewModel),
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              AppRoutes.volunteerProfileScreen,
                              arguments: user.uid,
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddFriendButton(
    VolunteerModel user,
    ProfileViewModel viewModel,
  ) {
    return FutureBuilder<FriendshipStatus>(
      future: viewModel.getFriendshipStatus(user.uid!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (snapshot.hasError) {
          return Text('Помилка: ${snapshot.error}');
        }
        final FriendshipStatus status =
            snapshot.data ?? FriendshipStatus.notFriends;
        switch (status) {
          case FriendshipStatus.notFriends:
            return ElevatedButton(
              onPressed: () {
                viewModel.sendFriendRequest(user.uid!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
              ),
              child: Text(
                'Додати в друзі',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            );
          case FriendshipStatus.requestSent:
            return ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.blueTransparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              ),
              child: Text(
                'Запит відправлено',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.backgroundLightGrey.withAlpha(179),
                ),
              ),
            );
          case FriendshipStatus.requestReceived:
            return ElevatedButton(
              onPressed: () {
                viewModel.acceptFriendRequestFromUser(user.uid!);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
              ),
              child: Text(
                'Прийняти запит',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            );

          case FriendshipStatus.friends:
            return ElevatedButton(
              onPressed: () {
                Constants.showConfirmationDialog(
                  context,
                  'Підтвердження видалення',
                  'Ви впевнені, що хочете видалити цього користувача зі своїх друзів?',
                  'Видалити',
                  viewModel,
                  user.uid!,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.errorRed.withAlpha(120),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
              ),
              child: Text(
                'Видалити з друзів',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            );

          case FriendshipStatus.self:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
