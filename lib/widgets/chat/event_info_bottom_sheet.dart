import 'package:flutter/material.dart';
import 'package:helphub/models/event_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import 'package:intl/intl.dart';

class EventInfoBottomSheet extends StatelessWidget {
  final EventModel event;

  const EventInfoBottomSheet({
    super.key,
    required this.event,
  });

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: appThemeColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              event.name,
              style: TextStyleHelper.instance.title20Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                  fontWeight: FontWeight.w900
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (event.description.isNotEmpty)
                    _buildSection(
                      title: 'Опис',
                      content: event.description,
                    ),
                  _buildSection(
                    title: 'Дата і час',
                    content: DateFormat('dd.MM.yyyy HH:mm').format(event.date),
                  ),
                  _buildSection(
                    title: 'Тривалість',
                    content: event.duration,
                  ),
                  _buildSection(
                    title: 'Місце проведення',
                    content: event.locationText,
                  ),
                  _buildSection(
                    title: 'Місто',
                    content: event.city,
                  ),
                  _buildSection(
                    title: 'Учасники',
                    content: '${event.participantIds.length}/${event.maxParticipants}',
                  ),
                  if (event.categories.isNotEmpty)
                    _buildSection(
                      title: 'Категорії',
                      content: event.categories.map((c) => c.title).join(', '),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}