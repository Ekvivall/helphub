import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/fundraising_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

class SavedFundraisingItem extends StatelessWidget {
  final FundraisingModel fundraising;

  const SavedFundraisingItem({super.key, required this.fundraising});

  @override
  Widget build(BuildContext context) {
    // Розрахунок прогресу для індикатора
    final progress =
        fundraising.targetAmount != null && fundraising.targetAmount! > 0
        ? (fundraising.currentAmount ?? 0) / fundraising.targetAmount!
        : 0.0;

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
          child: Row(
            children: [
              // Ліва частина: Зображення
              _buildImage(fundraising.photoUrl),
              const SizedBox(width: 12),
              // Права частина: Інформація
              Expanded(
                child: _buildInfo(
                  title: fundraising.title ?? 'Без назви',
                  organizationName:
                      fundraising.organizationName ?? 'Невідома організація',
                  progress: progress,
                ),
              ),
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

  // Віджет для текстової інформації та прогресу
  Widget _buildInfo({
    required String title,
    required String organizationName,
    required double progress,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyleHelper.instance.title16Bold.copyWith(
            color: appThemeColors.primaryBlack,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          organizationName,
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.blueAccent,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
        Text(
          '${(progress * 100).toStringAsFixed(0)}% зібрано',
          style: TextStyleHelper.instance.title13Regular.copyWith(
            color: appThemeColors.textMediumGrey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
