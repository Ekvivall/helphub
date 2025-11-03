import 'package:flutter/material.dart';
import 'package:helphub/data/services/fundraising_service.dart';
import 'package:helphub/data/models/activity_model.dart';
import 'package:helphub/data/models/fundraising_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/profile/report_section_widget.dart';
import 'package:intl/intl.dart';

import '../../routes/app_router.dart';
import '../custom_elevated_button.dart';

class FundraisingCreationActivityItem extends StatefulWidget {
  final ActivityModel activity;
  final bool isOwner;

  const FundraisingCreationActivityItem({
    super.key,
    required this.activity,
    required this.isOwner,
  });

  @override
  State<FundraisingCreationActivityItem> createState() =>
      _FundraisingCreationActivityItemState();
}

class _FundraisingCreationActivityItemState
    extends State<FundraisingCreationActivityItem> {
  bool _isCompleting = false;

  String _getFundraisingStatus(FundraisingModel fundraising) {
    final now = DateTime.now();
    final isCompleted = fundraising.status == 'completed';

    // Якщо збір завершений вручну (натиснута кнопка "Завершити")
    if (isCompleted) {
      return 'Завершений';
    }

    // Якщо ціль досягнута, але збір ще активний
    if (fundraising.currentAmount != null &&
        fundraising.targetAmount != null &&
        fundraising.currentAmount! >= fundraising.targetAmount!) {
      return 'Ціль досягнуто';
    }

    // Якщо термін збору закінчився
    if (fundraising.endDate != null && now.isAfter(fundraising.endDate!)) {
      return 'Термін завершено';
    }

    // Якщо збір ще не розпочався
    if (fundraising.startDate != null && now.isBefore(fundraising.startDate!)) {
      return 'Очікується';
    }

    // В інших випадках (активний)
    return 'Активний';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Активний':
        return appThemeColors.successGreen;
      case 'Завершений':
        return appThemeColors.textMediumGrey;
      case 'Очікується':
        return appThemeColors.blueAccent;
      case 'Ціль досягнуто':
        return appThemeColors.lightGreenColor;
      case 'Термін завершено':
        return appThemeColors.errorRed;
      default:
        return appThemeColors.textMediumGrey;
    }
  }

  bool _canBeCompleted(FundraisingModel fundraising) {
    final now = DateTime.now();
    final isEndDatePassed =
        fundraising.endDate != null && now.isAfter(fundraising.endDate!);
    final isTargetReached =
        fundraising.currentAmount != null &&
        fundraising.targetAmount != null &&
        fundraising.currentAmount! >= fundraising.targetAmount!;

    return (isEndDatePassed || isTargetReached) &&
        fundraising.status != 'completed';
  }

  Future<void> _completeFundraising(FundraisingModel fundraising) async {
    setState(() {
      _isCompleting = true;
    });

    try {
      // Показуємо діалог підтвердження
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Завершити збір',
            style: TextStyleHelper.instance.title18Bold,
          ),
          content: Text(
            'Ви впевнені, що хочете завершити збір "${fundraising.title}"? Після завершення збір буде неактивним.',
            style: TextStyleHelper.instance.title14Regular,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Скасувати',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.errorRed,
              ),
              child: Text(
                'Завершити',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final FundraisingService fundraisingService = FundraisingService();
        await fundraisingService.completeFundraising(fundraising.id!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Збір "${fundraising.title}" успішно завершено',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
              backgroundColor: appThemeColors.successGreen,
            ),
          );

          // Якщо є розіграш, переходимо на сторінку розіграшу
          if (fundraising.hasRaffle) {
            Navigator.of(context).pushNamed(
              AppRoutes.fundraisingRaffleScreen,
              arguments: fundraising.id,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Помилка завершення збору: ${e.toString()}',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
            backgroundColor: appThemeColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FundraisingService fundraisingService = FundraisingService();

    return FutureBuilder<FundraisingModel?>(
      future: fundraisingService.getFundraisingById(widget.activity.entityId),
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
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                'Не вдалося завантажити деталі збору',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
          );
        }

        final FundraisingModel fundraising = snapshot.data!;
        final String status = _getFundraisingStatus(fundraising);
        final Color statusColor = _getStatusColor(status);
        final double progress =
            fundraising.targetAmount != null && fundraising.targetAmount! > 0
            ? (fundraising.currentAmount ?? 0) / fundraising.targetAmount!
            : 0;
        final bool canBeCompleted = _canBeCompleted(fundraising);

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
                  children: [
                    Icon(
                      Icons.campaign,
                      color: appThemeColors.blueAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.isOwner
                          ? 'Ви створили збір коштів:'
                          : 'Створив збір коштів:',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Text(
                  fundraising.title ?? 'Без назви',
                  style: TextStyleHelper.instance.title18Bold.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(31),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withAlpha(77)),
                      ),
                      child: Text(
                        status,
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (fundraising.hasRaffle) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: appThemeColors.blueAccent.withAlpha(31),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: appThemeColors.blueAccent.withAlpha(77),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.casino,
                              size: 14,
                              color: appThemeColors.blueAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Розіграш',
                              style: TextStyleHelper.instance.title13Regular
                                  .copyWith(
                                    color: appThemeColors.blueAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Цільова сума:',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(fundraising.targetAmount ?? 0)} грн',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Зібрано:',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                    Text(
                      '${NumberFormat('#,###').format(fundraising.currentAmount ?? 0)} грн',
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 4),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: appThemeColors.textMediumGrey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Створено: ${DateFormat('dd.MM.yyyy').format(widget.activity.timestamp)}',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                  ],
                ),
                if (widget.isOwner) ...[
                  const SizedBox(height: 12),
                  // Показуємо кнопки, якщо статус не "Завершений"
                  if (status != 'Завершений') ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.fundraisingDonationsScreen,
                                arguments: fundraising.id,
                              );
                            },
                            backgroundColor: appThemeColors.successGreen,
                            borderRadius: 8,
                            height: 34,
                            text: 'Список донатів',
                            textStyle: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: appThemeColors.primaryWhite,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Редагувати збір доступно лише для активних зборів
                        if (status == 'Активний')
                          Expanded(
                            child: CustomElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.createFundraisingScreen,
                                  arguments: fundraising.id,
                                );
                              },
                              backgroundColor: appThemeColors.blueAccent,
                              borderRadius: 8,
                              height: 34,
                              text: 'Редагувати збір',
                              textStyle: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: appThemeColors.primaryWhite,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Кнопка "Завершити збір" показується лише якщо це дозволено
                    if (canBeCompleted)
                      CustomElevatedButton(
                        onPressed: _isCompleting
                            ? null
                            : () => _completeFundraising(fundraising),
                        backgroundColor: appThemeColors.errorRed,
                        borderRadius: 8,
                        height: 34,
                        text: _isCompleting
                            ? 'Завершення...'
                            : 'Завершити збір',
                        textStyle: TextStyleHelper.instance.title14Regular
                            .copyWith(
                              fontWeight: FontWeight.w700,
                              color: appThemeColors.primaryWhite,
                            ),
                      ),
                  ] else if (status == 'Завершений') ...[
                    Row(
                      children: [
                        if (fundraising.reportId == null) ...[
                          Expanded(
                            child: CustomElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pushNamed(
                                  AppRoutes.fundraisingDonationsScreen,
                                  arguments: fundraising.id,
                                );
                              },
                              backgroundColor: appThemeColors.blueAccent,
                              borderRadius: 8,
                              height: 34,
                              text: 'Список донатів',
                              textStyle: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: appThemeColors.primaryWhite,
                                  ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: buildReportSection(
                            fundraising.reportId,
                            widget.activity,
                            context,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Інші статуси (Очікується тощо)
                    CustomElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pushNamed(
                          AppRoutes.fundraisingDonationsScreen,
                          arguments: fundraising.id,
                        );
                      },
                      backgroundColor: appThemeColors.successGreen,
                      borderRadius: 8,
                      height: 34,
                      text: 'Список донатів',
                      textStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(
                            fontWeight: FontWeight.w700,
                            color: appThemeColors.primaryWhite,
                          ),
                    ),
                  ],
                ] else ...[
                  const SizedBox(height: 12),
                  CustomElevatedButton(
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
}
