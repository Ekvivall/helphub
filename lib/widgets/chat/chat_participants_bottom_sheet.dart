import 'package:flutter/material.dart';
import 'package:helphub/data/services/user_service.dart';
import 'package:helphub/data/models/chat_model.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/volunteer_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class ChatParticipantsBottomSheet extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final String organizerId;

  const ChatParticipantsBottomSheet({
    super.key,
    required this.chat,
    required this.currentUserId,
    required this.organizerId,
  });

  // Fetch all participants' profiles asynchronously
  Future<List<BaseProfileModel>> _fetchParticipants() async {
    final userService = UserService();
    final futures = chat.participants
        .map((id) => userService.fetchUserProfile(id))
        .toList();
    // Use Future.wait to fetch all profiles concurrently
    final results = await Future.wait(futures);
    return results.whereType<BaseProfileModel>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: appThemeColors.grey200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Учасники (${chat.participants.length})',
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              // Use FutureBuilder to handle the asynchronous data fetching
              child: FutureBuilder<List<BaseProfileModel>>(
                future: _fetchParticipants(),
                builder: (context, snapshot) {
                  // Show a loading indicator while the data is being fetched
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: appThemeColors.blueAccent,
                      ),
                    );
                  }
                  // Show an error message if something went wrong
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Помилка завантаження учасників: ${snapshot.error}',
                        style: TextStyleHelper.instance.title16Regular.copyWith(
                          color: appThemeColors.errorRed,
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasData) {
                    final users = snapshot.data!;
                    return ListView.separated(
                      controller: scrollController,
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        String displayName;
                        if (user is VolunteerModel) {
                          displayName =
                              user.fullName ?? user.displayName ?? 'Волонтер';
                        } else if (user is OrganizationModel) {
                          displayName = user.organizationName ?? 'Фонд';
                        } else {
                          displayName = 'Невідомий користувач';
                        }

                        return ListTile(
                          leading: UserAvatarWithFrame(
                            size: 24,
                            role: user.role!,
                            uid: user.uid!,
                            frame: user is VolunteerModel ? (user).frame : null,
                            photoUrl: user.photoUrl,
                          ),
                          title: Text(
                            displayName,
                            style: TextStyleHelper.instance.title16Regular
                                .copyWith(color: appThemeColors.primaryBlack),
                          ),
                          subtitle: user.uid == currentUserId
                              ? Text(
                                  'Ви',
                                  style: TextStyleHelper.instance.title13Regular
                                      .copyWith(
                                        color: appThemeColors.textMediumGrey,
                                      ),
                                )
                              : organizerId == user.uid
                              ? Text(
                                  'Організатор',
                                  style: TextStyleHelper.instance.title13Regular
                                      .copyWith(
                                        color: appThemeColors.blueAccent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                )
                              : null,
                        );
                      },
                      separatorBuilder: (BuildContext context, int index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(
                            color: appThemeColors.textMediumGrey.withAlpha(79),
                            height: 1,
                            thickness: 1,
                          ),
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
