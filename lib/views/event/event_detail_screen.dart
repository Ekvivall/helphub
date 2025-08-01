import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:helphub/models/organization_model.dart';
import 'package:helphub/models/volunteer_model.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/utils/constants.dart';
import '../../models/base_profile_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/events/action_button.dart';
import '../../widgets/events/small_location_map.dart';
import '../../widgets/profile/category_chip_widget.dart';

class EventDetailScreen extends StatefulWidget {
  final String eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  late EventViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<EventViewModel>(context, listen: false);
    _viewModel.loadEventDetails(widget.eventId);
  }

  @override
  void dispose() {
    _viewModel.clearEventDetails();
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Деталі події',
              style: TextStyleHelper.instance.headline24SemiBold.copyWith(
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
            begin: Alignment(0.9, -0.4),
            end: Alignment(-0.9, 0.4),
            colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
          ),
        ),
        child: Consumer<EventViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading && viewModel.currentEvent == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.successGreen,
                ),
              );
            }
            if (viewModel.errorMessage != null) {
              return Center(
                child: Text(
                  viewModel.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.blueMixedColor,
                  ),
                ),
              );
            }
            if (viewModel.currentEvent == null) {
              return Center(
                child: Text(
                  'Подію не знайдено.',
                  style: TextStyleHelper.instance.title16Regular.copyWith(
                    color: appThemeColors.blueMixedColor,
                  ),
                ),
              );
            }
            final event = viewModel.currentEvent!;
            final currentUserId = viewModel.currentAuthUserId;
            final isOrganizer = currentUserId == event.organizerId;
            final isParticipant = event.participantIds.contains(currentUserId);
            final bool isEventFinished = event.date.isBefore(DateTime.now());
            final bool isFull =
                event.participantIds.length >= event.maxParticipants;
            final int participantsCount = event.participantIds.length;
            final int maxParticipants = event.maxParticipants;
            final int remainingSpots = maxParticipants - participantsCount;
            final String participantsStatus =
                '$participantsCount/$maxParticipants учасників';
            final String remainingSpotsText = remainingSpots > 0
                ? 'залишилось $remainingSpots місць'
                : 'місць немає';
            final organizer = viewModel.organizer;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Фото події
                        Container(
                          height: 200,
                          width: double.infinity,
                          color: appThemeColors.grey200,
                          child: CustomImageView(
                            imagePath: event.photoUrl,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Назва події
                              Text(
                                event.name,
                                style:
                                TextStyleHelper.instance.headline24SemiBold,
                              ),
                              const SizedBox(height: 12),
                              // Категорія
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: event.categories
                                      .map(
                                        (category) =>
                                        CategoryChipWidget(chip: category),
                                  )
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Дата та час
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: appThemeColors.backgroundLightGrey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${DateFormat('dd.MM.yyyy').format(
                                        event.date)}, ${DateFormat('HH:mm')
                                        .format(event.date)} - ${DateFormat(
                                        'HH:mm').format(event.date.add(Duration(
                                        minutes: Constants
                                            .parseDurationStringToMinutes(
                                            event.duration) ?? 0)))}',
                                    style: TextStyleHelper
                                        .instance
                                        .title16Regular
                                        .copyWith(
                                      color: appThemeColors
                                          .backgroundLightGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Локація (коротко)
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: appThemeColors.backgroundLightGrey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${event.locationText}, ~${Constants
                                          .calculateDistance(
                                          event.locationGeoPoint, viewModel
                                          .currentUserLocation)} від вас',
                                      style: TextStyleHelper
                                          .instance
                                          .title16Regular
                                          .copyWith(
                                        color: appThemeColors
                                            .backgroundLightGrey,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // Учасники
                              Row(
                                children: [
                                  Icon(
                                    Icons.group,
                                    color: appThemeColors.backgroundLightGrey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$participantsCount учасників, потрібно $maxParticipants',
                                    style: TextStyleHelper
                                        .instance
                                        .title16Regular
                                        .copyWith(
                                      color: appThemeColors
                                          .backgroundLightGrey,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Опис події
                              Text(
                                'Про подію',
                                style: TextStyleHelper.instance.title18Bold
                                    .copyWith(
                                  color: appThemeColors.backgroundLightGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.description,
                                style: TextStyleHelper.instance.title16Regular
                                    .copyWith(
                                  color: appThemeColors.textLightColor,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                              const SizedBox(height: 24),
                              // Організатор
                              Text(
                                'Організатор',
                                style: TextStyleHelper.instance.title18Bold
                                    .copyWith(
                                  color: appThemeColors.backgroundLightGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  //Аватар організатора
                                  UserAvatarWithFrame(
                                    size: 24,
                                    photoUrl: organizer?.photoUrl,
                                    frame: organizer is VolunteerModel
                                        ? organizer.frame
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  if (organizer != null)
                                    Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          organizer is VolunteerModel
                                              ? organizer.fullName ??
                                              organizer.displayName ??
                                              'Волонтер'
                                              : organizer is OrganizationModel
                                              ? organizer.organizationName ??
                                              'Благодійний фонд'
                                              : 'Невідомий користувач',
                                          style: TextStyleHelper
                                              .instance
                                              .title16Bold
                                              .copyWith(
                                            color: appThemeColors
                                                .backgroundLightGrey,
                                          ),
                                        ),
                                        Text(
                                          '${organizer.eventsCount ??
                                              0} організованих подій',
                                          style: TextStyleHelper
                                              .instance
                                              .title14Regular
                                              .copyWith(
                                            color: appThemeColors
                                                .textLightColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // Локація (карта)
                              Text(
                                'Локація на карті:',
                                style: TextStyleHelper.instance.title18Bold
                                    .copyWith(
                                  color: appThemeColors.backgroundLightGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (event.locationGeoPoint != null)
                                SizedBox(
                                  height: 200,
                                  width: double.infinity,
                                  child: SmallLocationMap(
                                    location: LatLng(
                                      event.locationGeoPoint!.latitude,
                                      event.locationGeoPoint!.longitude,
                                    ),
                                    title: event.name,
                                    snippet: event.locationText,
                                  ),
                                ),
                              const SizedBox(height: 24),
                              Text(
                                'Друзі, які йдуть (${viewModel
                                    .participatingFriends.length}):',
                                style: TextStyleHelper.instance.title18Bold
                                    .copyWith(
                                  color: appThemeColors.backgroundLightGrey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              viewModel.participatingFriends.isEmpty
                                  ? Text(
                                'Наразі жоден з ваших друзів не долучився.',
                                style: TextStyleHelper
                                    .instance
                                    .title14Regular
                                    .copyWith(
                                  color:
                                  appThemeColors.textLightColor,
                                ),
                              )
                                  : _buildParticipatingFriendsList(
                                viewModel.participatingFriends,
                              ),
                              const SizedBox(height: 24),
                              // Друзі, які йдуть
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Нижня панель дій
                if (currentUserId != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: appThemeColors.backgroundLightGrey,
                      boxShadow: [
                        BoxShadow(
                          color: appThemeColors.primaryBlack.withAlpha(74),
                          blurRadius: 10,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: !isParticipant
                              ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                participantsStatus,
                                style: TextStyleHelper
                                    .instance
                                    .title16Bold
                                    .copyWith(
                                  color: appThemeColors.primaryBlack,
                                ),
                              ),
                              if (remainingSpotsText.isNotEmpty)
                                Text(
                                  remainingSpotsText,
                                  style: TextStyleHelper
                                      .instance
                                      .title14Regular
                                      .copyWith(
                                    color:
                                    appThemeColors.textMediumGrey,
                                  ),
                                ),
                            ],
                          )
                              : CustomElevatedButton(
                            text: viewModel.isJoiningLeaving
                                ? 'Залишаю...'
                                : 'Залишити подію',
                            onPressed: viewModel.isJoiningLeaving
                                ? null
                                : () async {
                              final result = await viewModel
                                  .leaveEvent(
                                event.id!,
                                currentUserId,
                              );
                              if (result != null) {
                                Constants.showErrorMessage(
                                  context,
                                  'Помилка: $result',
                                );
                              }
                            },
                            backgroundColor: appThemeColors.errorRed,
                            height: 48,
                            textStyle: TextStyleHelper
                                .instance
                                .title16Bold
                                .copyWith(
                              color: appThemeColors.primaryWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        buildActionButton(
                          context,
                          viewModel,
                          event,
                          currentUserId,
                          isOrganizer,
                          isParticipant,
                          isEventFinished,
                          isFull,
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildParticipatingFriendsList(List<BaseProfileModel?> friends) {
    final List<Widget> friendWidgets = friends
        .map(
            (friend) {
          VolunteerModel? currentFriend = friend is VolunteerModel ? friend : null;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Column(
              children: [
                UserAvatarWithFrame(
                  size: 20,
                  photoUrl: currentFriend?.photoUrl,
                  frame: currentFriend?.frame,
                ),
                const SizedBox(height: 4),
                Text(
                  currentFriend?.fullName ?? currentFriend?.displayName ?? '',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
    )
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: friendWidgets),
    );
  }
}
