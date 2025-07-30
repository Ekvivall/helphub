import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/models/event_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_image_view.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';

class EventListItem extends StatelessWidget {
  final EventModel event;
  final GeoPoint? userCurrentLocation;

  const EventListItem({
    super.key,
    required this.event,
    this.userCurrentLocation,
  });

  String _calculateDistance(GeoPoint? eventLocation, GeoPoint? userLocation) {
    if (eventLocation == null || userLocation == null) {
      return '';
    }
    double distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} м';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} км';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String distanceText = _calculateDistance(
      event.locationGeoPoint,
      userCurrentLocation,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      //color: appThemeColors.blueMixedColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          //TODO: Перехід на екран деталізації події
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
                        '${event.date.day}.${event.date.month}.${event.date.year}, ${event.startTime}',
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
                    onPressed: () {
                      //TODO: логіка для долучення до події
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: appThemeColors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Долучитися',
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
