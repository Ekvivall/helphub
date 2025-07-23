import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_image_view.dart';

class FriendsListScreen extends StatelessWidget {
  const FriendsListScreen({super.key});

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
          'Мої друзі',
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
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.friendProfiles.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }
            if (viewModel.friendProfiles.isEmpty) {
              return Center(
                child: Text(
                  'У вас поки що немає друзів.',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.builder(
              itemCount: viewModel.friendProfiles.length,
              itemBuilder: (context, index) {
                final friend = viewModel.friendProfiles[index];
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
                        AppRoutes.volunteerProfileScreen,
                        arguments: friend.uid,
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundColor: appThemeColors.lightGreenColor,
                                backgroundImage: friend.photoUrl != null
                                    ? NetworkImage(friend.photoUrl!)
                                    : null,
                                child: friend.photoUrl == null
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: appThemeColors.primaryWhite,
                                      )
                                    : null,
                              ),
                              if (friend.frame != null &&
                                  friend.frame!.isNotEmpty)
                                CustomImageView(
                                  imagePath: friend.frame!,
                                  height: 50,
                                  width: 50,
                                  fit: BoxFit.contain,
                                ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  friend.fullName ??
                                      friend.displayName ??
                                      'Невідомий користувач',
                                  style: TextStyleHelper
                                      .instance
                                      .title16ExtraBold
                                      .copyWith(
                                        color: appThemeColors.primaryBlack,
                                      ),
                                ),
                                if (friend.city != null &&
                                    friend.city!.isNotEmpty)
                                  Text(
                                    'м. ${friend.city!}',
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
                            onPressed: () {
                              // TODO: Implement navigation to chat screen
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
    );
  }
}
