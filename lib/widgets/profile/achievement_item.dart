import 'package:flutter/material.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/data/models/achievement_item_model.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../custom_image_view.dart';

class AchievementItemWidget extends StatelessWidget {
  final AchievementModel achievement;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementItemWidget({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAchievementDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked
              ? appThemeColors.primaryWhite
              : appThemeColors.backgroundLightGrey.withAlpha(100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUnlocked
                ? appThemeColors.lightGreenColor
                : appThemeColors.grey200,
            width: isUnlocked ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Іконка досягнення
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Opacity(
                      opacity: isUnlocked ? 1 : 0.3,
                      child: CustomImageView(
                        imagePath: achievement.isSecret && !isUnlocked
                            ? ImageConstant.llamaSecretClose
                            : achievement.iconPath,
                        width: 113,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Індикатор розблокування
                  if (isUnlocked)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Icon(
                        Icons.check_circle,
                        color: appThemeColors.lightGreenColor,
                        size: 20,
                        shadows: [
                          Shadow(
                            color: Colors.black.withAlpha(193),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(
                achievement.isSecret && !isUnlocked ? '???' : achievement.title,
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: isUnlocked
                      ? appThemeColors.primaryBlack
                      : appThemeColors.textMediumGrey,
                  fontWeight: isUnlocked ? FontWeight.w600 : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemeColors.primaryWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isUnlocked ? 1.0 : 0.5,
              child: CustomImageView(
                imagePath: achievement.isSecret && !isUnlocked
                    ? ImageConstant.llamaSecretClose
                    : achievement.iconPath,
                height: 180,
                width: 180,
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(height: 16),
            Text(
              achievement.isSecret && !isUnlocked
                  ? 'Секретне досягнення'
                  : achievement.title,
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              achievement.isSecret && !isUnlocked
                  ? 'Продовжуй відкривати нові досягнення, щоб розблокувати це!'
                  : achievement.description,
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
            if (isUnlocked && unlockedAt != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: appThemeColors.lightGreenColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: appThemeColors.lightGreenColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Розблоковано ${_formatDate(unlockedAt!)}',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.lightGreenColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (!isUnlocked) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: appThemeColors.grey200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lock,
                      color: appThemeColors.textMediumGrey,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Заблоковано',
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.textMediumGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Закрити',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.blueAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
