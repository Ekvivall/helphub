import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class FriendRequestsScreen extends StatelessWidget {
  const FriendRequestsScreen({super.key});

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
          'Заявки в друзі',
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
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (viewModel.incomingFriendRequests.isEmpty) {
              return Center(
                child: Text(
                  'У вас немає вхідних заявок у друзі.',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return ListView.builder(
              itemCount: viewModel.incomingFriendRequestsCount,
              itemBuilder: (context, index) {
                final request = viewModel.incomingFriendRequests[index];
                return Card(
                  color: appThemeColors.backgroundLightGrey,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        request.senderPhotoUrl != null &&
                                request.senderPhotoUrl!.isNotEmpty
                            ? CustomImageView(
                                imagePath: request.senderPhotoUrl!,
                                height: 50,
                                width: 50,
                                radius: BorderRadius.circular(25),
                                fit: BoxFit.cover,
                              )
                            : CircleAvatar(
                                radius: 25,
                                backgroundColor: appThemeColors.lightGreenColor,
                                child: Icon(
                                  Icons.person,
                                  size: 45,
                                  color: appThemeColors.primaryWhite,
                                ),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                request.senderDisplayName,
                                style: TextStyleHelper.instance.title16Bold
                                    .copyWith(
                                      color: appThemeColors.primaryBlack,
                                    ),
                              ),
                              Text(
                                'Надіслав(ла) вам заявку в друзі.',
                                style: TextStyleHelper.instance.title16Regular
                                    .copyWith(
                                      color: appThemeColors.textMediumGrey,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                viewModel.acceptFriendRequestFromUser(
                                  request.senderId,
                                );
                                Constants.showSuccessMessage(context, 'Заявку прийнято!');
                              },
                              icon: Icon(
                                Icons.check,
                                color: appThemeColors.successGreen,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                viewModel.rejectFriendRequestFromUser(
                                  request.senderId,
                                );
                                Constants.showSuccessMessage(context, 'Заявку відхилено!');
                              },
                              icon: Icon(
                                Icons.close,
                                color: appThemeColors.errorRed,
                              ),
                            ),
                          ],
                        ),
                      ],
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
