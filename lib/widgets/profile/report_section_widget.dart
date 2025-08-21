import 'package:flutter/material.dart';
import 'package:helphub/models/activity_model.dart';

import '../../core/services/report_service.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../custom_elevated_button.dart';

Widget buildReportSection(
  String? reportId,
  ActivityModel activity,
  BuildContext context,
) {

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (reportId != null) ...[
        // Показати інформацію про звіт та відгуки
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appThemeColors.successGreen.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: appThemeColors.successGreen.withAlpha(77),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment_turned_in,
                    color: appThemeColors.successGreen,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Звіт створено',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.successGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: _getOrganizerFeedbackCount(reportId),
                builder: (context, snapshot) {
                  final feedbackCount = snapshot.data ?? 0;
                  return Text(
                    feedbackCount > 0
                        ? 'Отримано $feedbackCount відгук${feedbackCount == 1
                              ? ''
                              : feedbackCount < 5
                              ? 'и'
                              : 'ів'} від учасників'
                        : 'Поки немає відгуків від учасників',
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
      // Кнопки для роботи зі звітом
      if (reportId == null)
        CustomElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed(
              AppRoutes.createReportScreen,
              arguments: {'activity': activity},
            );
          },
          backgroundColor: appThemeColors.successGreen,
          borderRadius: 8,
          height: 34,
          text: 'Додати звіт',
          textStyle: TextStyleHelper.instance.title14Regular.copyWith(
            fontWeight: FontWeight.w700,
            color: appThemeColors.primaryWhite,
          ),
        )
      else
        Row(
          children: [
            Expanded(
              child: CustomElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.viewReportScreen, arguments: {
                    'reportId': reportId,
                    'canLeaveFeedback': false
                  },);
                },
                backgroundColor: appThemeColors.blueAccent,
                borderRadius: 8,
                height: 34,
                text: 'Переглянути звіт',
                textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CustomElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(
                    AppRoutes.createReportScreen,
                    arguments: {'reportId': reportId},
                  );
                },
                backgroundColor: appThemeColors.textMediumGrey,
                borderRadius: 8,
                height: 34,
                text: 'Редагувати',
                textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                  fontWeight: FontWeight.w700,
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        ),
    ],
  );
}

Future<int> _getOrganizerFeedbackCount(String reportId) async {
  final report = await ReportService().getReportById(reportId);
  return report?.organizerFeedback.length ?? 0;
}
