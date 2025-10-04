import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/fundraising_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:intl/intl.dart';

class ActiveFundraisingItem extends StatelessWidget {
  final FundraisingModel fundraising;

  final bool isOwner;

  const ActiveFundraisingItem({super.key, required this.fundraising, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    // Розрахунок прогресу для індикатора
    final progress =
    fundraising.targetAmount != null && fundraising.targetAmount! > 0
        ? (fundraising.currentAmount ?? 0) / fundraising.targetAmount!
        : 0.0;

    // Розрахунок днів що залишилось
    final daysLeft = fundraising.endDate != null
        ? fundraising.endDate!.difference(DateTime.now()).inDays
        : 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Навігація на детальний екран при натисканні
          Navigator.of(context).pushNamed(
            AppRoutes.fundraisingDetailScreen,
            arguments: fundraising.id,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Ліва частина: Зображення
                  _buildImage(fundraising.photoUrl),
                  const SizedBox(width: 12),
                  // Права частина: Основна інформація
                  Expanded(
                    child: _buildMainInfo(
                      title: fundraising.title ?? 'Без назви',
                      progress: progress,
                      daysLeft: daysLeft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Нижня частина: Фінансові дані
              _buildFinancialInfo(),
              const SizedBox(height: 8),
              // Кнопки дій
              if(isOwner)
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // Віджет для зображення
  Widget _buildImage(String? photoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: photoUrl != null
            ? CachedNetworkImage(
          imageUrl: photoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: appThemeColors.textMediumGrey.withAlpha(50),
          ),
          errorWidget: (context, url, error) =>
          const Icon(Icons.image_not_supported, color: Colors.grey),
        )
            : Container(
          color: appThemeColors.textMediumGrey.withAlpha(50),
          child: Icon(
            Icons.volunteer_activism,
            color: appThemeColors.textMediumGrey,
            size: 40,
          ),
        ),
      ),
    );
  }

  // Віджет для основної інформації
  Widget _buildMainInfo({
    required String title,
    required double progress,
    required int daysLeft,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (fundraising.isUrgent == true)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: appThemeColors.errorRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ТЕРМІНОВО',
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                    fontWeight: FontWeight.w700,
                  ),
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
          minHeight: 5,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}% зібрано',
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.textMediumGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              daysLeft > 0 ? '$daysLeft днів' : 'Завершується сьогодні',
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: daysLeft <= 3
                    ? appThemeColors.errorRed
                    : appThemeColors.textMediumGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Віджет для фінансової інформації
  Widget _buildFinancialInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Зібрано',
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            Text(
              '${NumberFormat('#,###').format(fundraising.currentAmount ?? 0)} грн',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.successGreen,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Ціль',
              style: TextStyleHelper.instance.title13Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
            ),
            Text(
              '${NumberFormat('#,###').format(fundraising.targetAmount ?? 0)} грн',
              style: TextStyleHelper.instance.title16Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Віджет для кнопок дій
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.fundraisingDonationsScreen,
                arguments: fundraising.id,
              );
            },
            icon: Icon(
              Icons.people_outline,
              size: 16,
              color: appThemeColors.blueAccent,
            ),
            label: Text(
              'Донати',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.blueAccent,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: appThemeColors.blueAccent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pushNamed(
                AppRoutes.createFundraisingScreen,
                arguments: fundraising.id,
              );
            },
            icon: Icon(
              Icons.edit,
              size: 16,
              color: appThemeColors.primaryWhite,
            ),
            label: Text(
              'Редагувати',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: appThemeColors.blueAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              minimumSize: const Size(0, 36),
            ),
          ),
        ),
      ],
    );
  }
}