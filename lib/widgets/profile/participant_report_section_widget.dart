import 'package:flutter/material.dart';
import '../../data/services/report_service.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../custom_elevated_button.dart';

Widget buildParticipantReportSection(String? reportId, String currentUserId, bool isOwner, BuildContext context) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const SizedBox(height: 8),
      if (reportId != null) ...[
        // Показати інформацію про звіт
      if(isOwner)
      Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: appThemeColors.blueAccent.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: appThemeColors.blueAccent.withAlpha(77),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: appThemeColors.blueAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Звіт доступний',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.blueAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Показати відгук організатора про цього учасника
              FutureBuilder<String?>(
                future: _getParticipantFeedback(reportId, currentUserId),
                builder: (context, snapshot) {
                  final feedback = snapshot.data;
                  if (feedback != null && feedback.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: appThemeColors.successGreen.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Відгук організатора:',
                            style: TextStyleHelper.instance.title13Regular.copyWith(
                              color: appThemeColors.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            feedback,
                            style: TextStyleHelper.instance.title13Regular.copyWith(
                              color: appThemeColors.primaryBlack,
                            ), textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Text(
                      'Організатор ще не залишив відгук',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),
              // Показати статус власного відгуку про організатора
              FutureBuilder<bool>(
                future: _hasUserLeftFeedback(reportId, currentUserId),
                builder: (context, snapshot) {
                  final hasLeftFeedback = snapshot.data ?? false;
                  return Text(
                    hasLeftFeedback
                        ? 'Ви залишили відгук про організатора'
                        : 'Ви можете залишити відгук про організатора',
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: hasLeftFeedback
                          ? appThemeColors.successGreen
                          : appThemeColors.blueAccent,
                      fontWeight: hasLeftFeedback ? FontWeight.w600 : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Кнопка перегляду звіту
        CustomElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed(
              AppRoutes.viewReportScreen,
              arguments: {
                'reportId': reportId,
                'canLeaveFeedback': isOwner, // Учасник може залишити відгук
              },
            );
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
      ] else ...[
        // Звіт ще не створено
        Text(
          'Очікується звіт від організатора',
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    ],
  );
}

Future<String?> _getParticipantFeedback(String reportId, String participantId) async {
  final reportService = ReportService();
  final feedbackModel = await reportService.getParticipantFeedback(reportId, participantId);
  return feedbackModel?.feedback;
}

Future<bool> _hasUserLeftFeedback(String reportId, String userId) async {
  final reportService = ReportService();
  return await reportService.hasUserLeftFeedback(reportId, userId);
}