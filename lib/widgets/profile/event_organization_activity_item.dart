import 'package:flutter/material.dart';
import 'package:helphub/core/services/event_service.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/event_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:intl/intl.dart';

import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class EventOrganizationActivityItem extends StatelessWidget {
  final ActivityModel activity;

  const EventOrganizationActivityItem({super.key, required this.activity});

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
                'Не вдалося завантажити деталі організованої події: ${snapshot.error ?? "Подія не знайдена"}',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
          );
        }

        final EventModel event = snapshot.data!;
        // Перевіряємо, чи подія вже завершилася
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
                        event.name, // Назва події
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
                const SizedBox(height: 4),
                // Статус "Організатор"
                _buildInfoRow(
                  icon: Icons.business_center_outlined,
                  // Або інша відповідна іконка
                  text: 'Організатор',
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(height: 4),
                // Дата, місце, час
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  text:
                      '${DateFormat('dd.MM.yyyy').format(event.date)}, ${DateFormat('HH:mm').format(event.date)} - ${DateFormat('HH:mm').format(endTime)}',
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(width: 14),
                _buildInfoRow(
                  icon: Icons.location_on,
                  text: event.locationText,
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(height: 8),
                // Кнопки "Відредагувати" або "Додати звіт"
                if (!isEventFinished)
                  CustomElevatedButton(
                    onPressed: () {
                      // TODO: Визначити правильний маршрут для редагування події
                      // Можливо, це буде EventCreationScreen або EventEditScreen
                      Navigator.of(context).pushNamed(
                        AppRoutes.createEventScreen,
                        arguments: event.id,
                      );
                    },
                    backgroundColor: appThemeColors.blueAccent,
                    borderRadius: 8,
                    height: 34,
                    text: 'Відредагувати',
                    textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                      fontWeight: FontWeight.w700,
                      color: appThemeColors.primaryWhite,
                    ),
                  )
                else // Подія завершена
                  event.reportId == null
                      ? CustomElevatedButton(
                          onPressed: () {
                            // TODO: Реалізувати логіку переходу на екран додавання звіту
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Перехід до додавання звіту для "${event.name}" (не реалізовано)',
                                ),
                              ),
                            );
                            // Navigator.of(context).pushNamed(AppRoutes.createReportScreen, arguments: event.id);
                          },
                          backgroundColor: appThemeColors.successGreen,
                          // Зелена кнопка для додавання звіту
                          borderRadius: 8,
                          height: 34,
                          text: 'Додати звіт',
                          textStyle: TextStyleHelper.instance.title14Regular
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                color: appThemeColors.primaryWhite,
                              ),
                        )
                      : CustomElevatedButton(
                          onPressed: () {
                            // TODO: Реалізувати логіку переходу на екран перегляду звіту
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Перехід до перегляду звіту для "${event.name}" (не реалізовано)',
                                ),
                              ),
                            );
                            // Navigator.of(context).pushNamed(AppRoutes.viewReportScreen, arguments: event.reportId);
                          },
                          backgroundColor: appThemeColors.textMediumGrey,
                          // Сіра кнопка, якщо звіт є
                          borderRadius: 8,
                          height: 34,
                          text: 'Переглянути звіт',
                          textStyle: TextStyleHelper.instance.title14Regular
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                color: appThemeColors.primaryWhite,
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
