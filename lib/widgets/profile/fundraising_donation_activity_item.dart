import 'package:flutter/material.dart';
import 'package:helphub/core/services/fundraising_service.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/fundraising_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:intl/intl.dart';

class FundraisingDonationActivityItem extends StatelessWidget {
  final ActivityModel activity;
  final bool isOwner;

  const FundraisingDonationActivityItem({
    super.key,
    required this.activity,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final FundraisingService fundraisingService = FundraisingService();

    return FutureBuilder<FundraisingModel?>(
      future: fundraisingService.getFundraisingById(activity.entityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            margin: EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Не вдалося завантажити деталі збору',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
          );
        }

        final FundraisingModel fundraising = snapshot.data!;
        final progress =
            fundraising.targetAmount != null && fundraising.targetAmount! > 0
            ? (fundraising.currentAmount ?? 0) / fundraising.targetAmount!
            : 0.0;

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
                // Заголовок активності
                Row(
                  children: [
                    Icon(
                      Icons.volunteer_activism,
                      color: appThemeColors.successGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isOwner
                          ? 'Ви задонатили на збір:'
                          : 'Задонатив(ла) на збір:',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Назва збору
                Text(
                  fundraising.title ?? 'Без назви',
                  style: TextStyleHelper.instance.title18Bold.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Організатор
                Text(
                  fundraising.organizationName ?? 'Невідома організація',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.blueAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),

                // Прогрес бар
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: appThemeColors.textMediumGrey.withAlpha(77),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0
                        ? appThemeColors.successGreen
                        : appThemeColors.blueAccent,
                  ),
                  minHeight: 6,
                ),
                const SizedBox(height: 8),

                // Дата донату
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd.MM.yyyy').format(activity.timestamp),
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                    const SizedBox(width: 15,),
                    Expanded(
                      child: CustomElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.fundraisingDetailScreen,
                            arguments: fundraising.id,
                          );
                        },
                        backgroundColor: appThemeColors.blueAccent,
                        borderRadius: 8,
                        height: 34,
                        text: 'Переглянути збір',
                        textStyle: TextStyleHelper.instance.title14Regular
                            .copyWith(
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
        );
      },
    );
  }
}
