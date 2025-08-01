import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/models/event_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:intl/intl.dart';

import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class EventListItem extends StatelessWidget {
  final EventModel event;
  final EventViewModel viewModel;
  final GeoPoint? userCurrentLocation;

  const EventListItem({
    super.key,
    required this.event,
    this.userCurrentLocation,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final String distanceText = Constants.calculateDistance(
      event.locationGeoPoint,
      userCurrentLocation,
    );
    final currentUserId = viewModel.currentAuthUserId;
    final isOrganizer = currentUserId == event.organizerId;
    final isParticipant = event.participantIds.contains(currentUserId);
    final bool isEventFinished = event.date.isBefore(DateTime.now());
    final bool isFull = event.participantIds.length >= event.maxParticipants;
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressedAction;
    bool isButtonEnabled = true;

    if (isEventFinished) {
      buttonText = 'Завершена';
      buttonColor = appThemeColors.textLightColor;
      onPressedAction = null;
      isButtonEnabled = false;
    } else if (isOrganizer) {
      buttonText = 'Ви організатор';
      buttonColor = appThemeColors.blueAccent;
      onPressedAction = null;
      isButtonEnabled = false;
    } else if (isParticipant) {
      buttonText = 'Ви долучились';
      buttonColor = appThemeColors.successGreen.withAlpha(174);
      onPressedAction = null;
      isButtonEnabled = false;
    } else if (isFull) {
      buttonText = 'Місць немає';
      buttonColor = appThemeColors.textLightColor;
      onPressedAction = null;
      isButtonEnabled = false;
    } else {
      buttonText = viewModel.isJoiningLeaving ? 'Долучаюсь...' : 'Долучитися';
      buttonColor = appThemeColors.blueAccent;
      onPressedAction = viewModel.isJoiningLeaving
          ? null
          : () async {
              if (currentUserId != null) {
                final result = await viewModel.joinEvent(event, currentUserId);
                if (result != null) {
                  Constants.showErrorMessage(context, 'Помилка: $result');
                }
              }
            };
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      //color: appThemeColors.blueMixedColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).pushNamed(AppRoutes.eventDetailScreen, arguments: event.id);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фото події
              if (event.photoUrl != null && event.photoUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CustomImageView(
                    imagePath: event.photoUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeHolder: ImageConstant.imgImageNotFound,
                  ),
                ),
              if (event.photoUrl != null && event.photoUrl!.isNotEmpty)
                const SizedBox(height: 12),
              // Назва події
              Text(
                event.name,
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              // Інформаційний блок (дата, час, місце, відстань)
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _buildInfoRow(
                    icon: Icons.calendar_today,
                    text:
                        '${event.date.day}.${event.date.month}.${event.date.year}, ${DateFormat('HH:mm').format(event.date)}',
                  ),
                  const SizedBox(width: 8),
                  _buildInfoRow(icon: Icons.timer, text: event.duration),
                  const SizedBox(width: 4),
                  _buildInfoRow(
                    icon: Icons.location_on,
                    text: event.locationText,
                  ),
                  const SizedBox(width: 4),
                  if (distanceText != "")
                    _buildInfoRow(
                      icon: Icons.directions_walk,
                      text: distanceText,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Категорії
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: event.categories
                    .map((category) => CategoryChipWidget(chip: category))
                    .toList(),
              ),
              const SizedBox(height: 8),
              // Кількість учасників та кнопка "Долучитися"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        size: 16,
                        color: appThemeColors.primaryBlack,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Долучилось: ${event.participantIds.length} з ${event.maxParticipants}',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: onPressedAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: isButtonEnabled ? 2 : 0,
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        fontWeight: FontWeight.w700,
                        color: appThemeColors.primaryWhite,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String text}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: appThemeColors.textMediumGrey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
