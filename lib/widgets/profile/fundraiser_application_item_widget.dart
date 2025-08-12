import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/fundraiser_application_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:intl/intl.dart';

class FundraiserApplicationItem extends StatelessWidget {
  final FundraiserApplicationModel application;

  const FundraiserApplicationItem({
    super.key,
    required this.application,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appThemeColors.blueMixedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            application.title,
            style: TextStyleHelper.instance.title18Bold,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Статус:',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              _buildStatusText(application.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Сума:',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${NumberFormat('#,##0', 'uk').format(application.requiredAmount)} грн',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Дедлайн:',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('dd.MM.yyyy').format(application.deadline.toDate()),
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Додаємо опис заявки
          if (application.description.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Опис:',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ExpandableText(
                  application.description,
                  expandText: 'докладніше',
                  collapseText: 'згорнути',
                  maxLines: 3,
                  linkColor: appThemeColors.blueAccent,
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.primaryBlack.withAlpha(175),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          // Організація (якщо є)
          if (application.organizationId.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Загальна заявка (всі фонди)',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.primaryBlack.withAlpha(175),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          Text(
            'Відправлено: ${DateFormat('dd.MM.yyyy').format(application.timestamp.toDate())}',
            style: TextStyleHelper.instance.title13Regular.copyWith(
              color: appThemeColors.primaryBlack.withAlpha(175),
            ),
          ),
          // Показуємо причину відхилення, якщо є
          if (application.status == FundraisingStatus.rejected &&
              application.rejectionReason != null &&
              application.rejectionReason!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: appThemeColors.errorRed.withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Причина відхилення:',
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application.rejectionReason!,
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.errorRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(FundraisingStatus status) {
    Color statusColor = appThemeColors.primaryBlack;
    String statusText = 'Невідомий';

    switch (status) {
      case FundraisingStatus.pending:
        statusText = 'На розгляді';
        statusColor = appThemeColors.blueAccent;
        break;
      case FundraisingStatus.approved:
        statusText = 'Схвалено';
        statusColor = appThemeColors.successGreen;
        break;
      case FundraisingStatus.rejected:
        statusText = 'Відхилено';
        statusColor = appThemeColors.errorRed;
        break;
      case FundraisingStatus.completed:
        statusText = 'Завершено';
        statusColor = appThemeColors.primaryBlack.withAlpha(150);
        break;
      case FundraisingStatus.active:
        statusText =  'В процесі';
        statusColor = appThemeColors.orangeAccent;
        break;
    }

    return Text(
      statusText,
      style: TextStyleHelper.instance.title14Regular.copyWith(
        color: statusColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}