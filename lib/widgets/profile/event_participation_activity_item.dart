import 'package:flutter/material.dart';
import 'package:helphub/core/services/event_service.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/event_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:intl/intl.dart';

class EventParticipationActivityItem extends StatelessWidget {
  final ActivityModel activity;

  const EventParticipationActivityItem({super.key, required this.activity});

  @override
  Widget build(BuildContext context) {
    final EventService eventService = EventService();

    return FutureBuilder<EventModel?>(
      future: eventService.getEventById(activity.entityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
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
                    // TODO: Реалізувати логіку переходу до чату події
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: appThemeColors.blueAccent,
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Перехід до чату події "${event.name}" (не реалізовано)',
                            ),
                          ),
                        );
                        // Navigator.of(context).pushNamed(AppRoutes.eventChatScreen, arguments: event.id);
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
                SizedBox(height: 4,),
                // Статус "Учасник"
                _buildInfoRow(
                  icon: Icons.person_outline,
                  text: 'Учасник',
                  color: appThemeColors.textMediumGrey,
                ),
                Row(
                  children: [
                    // Дата, місце, час
                    _buildInfoRow(
                      icon: Icons.calendar_today,
                      text:
                          '${DateFormat('dd.MM.yyyy').format(event.date)}, ${DateFormat('HH:mm').format(event.date)} - ${DateFormat('HH:mm').format(endTime)}',
                      color: appThemeColors.textMediumGrey,
                    ),
                    SizedBox(width: 14),
                    _buildInfoRow(
                      icon: Icons.location_on,
                      text: event.locationText,
                      color: appThemeColors.textMediumGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Кнопка "Деталі" або "Посилання на звіт"
                if (!isEventFinished)
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
                  )
                else // Подія завершена
                  // TODO: Додати логіку для посилання на звіт, коли вона буде реалізована
                  Text(
                    'Подія завершена${event.reportId != null ? ' (Є звіт)' : ''}', // Заглушка для звіту
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
                // Сіра рамка для коментаря організатора (placeholder)
                // TODO: Реалізувати отримання коментаря організатора для конкретного учасника
                if (false /* event.organizerCommentForParticipant != null */ ) // Заглушка, поки немає поля в моделі
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: appThemeColors.grey100, // Світло-сірий фон
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: appThemeColors.grey400),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Коментар організатора:',
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(color: appThemeColors.primaryBlack),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Тут буде коментар організатора до цього учасника про його участь.',
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(color: appThemeColors.textMediumGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
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
