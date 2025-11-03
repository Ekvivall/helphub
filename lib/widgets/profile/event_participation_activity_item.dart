import 'package:flutter/material.dart';
import 'package:helphub/data/services/event_service.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/data/models/activity_model.dart';
import 'package:helphub/data/models/event_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:helphub/widgets/profile/participant_report_section_widget.dart';
import 'package:intl/intl.dart';

class EventParticipationActivityItem extends StatelessWidget {
  final ActivityModel activity;
  final bool isOwner;
  final String currentAuthId;

  const EventParticipationActivityItem({
    super.key,
    required this.activity,
    required this.isOwner,
    required this.currentAuthId,
  });

  @override
  Widget build(BuildContext context) {
    final EventService eventService = EventService();

    return FutureBuilder<EventModel?>(
      future: eventService.getEventById(activity.entityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Не вдалося завантажити деталі події: ${snapshot.error ?? "Подія не знайдена"}',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
          );
        }

        final EventModel event = snapshot.data!;
        final bool isEventFinished = event.date.isBefore(DateTime.now());

        // Розрахунок кінцевого часу
        final int? durationMinutes = Constants.parseDurationStringToMinutes(
          event.duration,
        );
        final DateTime endTime = durationMinutes != null
            ? event.date.add(Duration(minutes: durationMinutes))
            : event.date;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.name,
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isOwner)
                      IconButton(
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          color: appThemeColors.blueAccent,
                        ),
                        onPressed: () async {
                          final eventService = EventService();
                          String? chatId = await eventService.getEventChatId(event.id!);
                          if(chatId != null) {
                            Navigator.of(context).pushNamed(
                            AppRoutes.chatEventScreen,
                            arguments: chatId,
                          );
                          }
                        },
                      ),
                  ],
                ),
                // Категорії
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: event.categories
                      .map((category) => CategoryChipWidget(chip: category))
                      .toList(),
                ),
                SizedBox(height: 4),
                // Статус "Учасник"
                _buildInfoRow(
                  icon: Icons.person_outline,
                  text: 'Учасник',
                  color: appThemeColors.textMediumGrey,
                ),
                // Дата, місце, час
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  text:
                      '${DateFormat('dd.MM.yyyy').format(event.date)}, ${DateFormat('HH:mm').format(event.date)} - ${DateFormat('HH:mm').format(endTime)}',
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(height: 4),
                _buildInfoRow(
                  icon: Icons.location_on,
                  text: event.locationText,
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(height: 8),
                if (isEventFinished) ...[
                  buildParticipantReportSection(
                    event.reportId,
                    currentAuthId,
                    isOwner,
                    context,
                  ),
                ] else ...[
                  CustomElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                        AppRoutes.eventDetailScreen,
                        arguments: event.id,
                      );
                    },
                    backgroundColor: appThemeColors.blueAccent,
                    borderRadius: 8,
                    height: 34,
                    text: 'Деталі',
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appThemeColors.primaryWhite,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? appThemeColors.textMediumGrey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: color ?? appThemeColors.textMediumGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
