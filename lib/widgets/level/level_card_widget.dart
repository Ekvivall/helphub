import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';

import '../../core/utils/constants.dart';

class LevelCardWidget extends StatelessWidget {
  final int userPoints;
  final int currentLevel;
  final bool isOwner;

  const LevelCardWidget({
    super.key,
    required this.userPoints,
    required this.currentLevel,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final levelData = Constants.getLevelByNumber(currentLevel);
    final nextLevel = Constants.getNextLevel(currentLevel);
    final progress = levelData.getProgress(userPoints);
    final pointsToNext = levelData.getPointsToNext(userPoints);
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 28, vertical: 7),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              appThemeColors.blueMixedColor,
              appThemeColors.blueMixedColor.withAlpha(146),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: appThemeColors.cyanAccent, width: 2),
        ),
        child: Column(
          children: [
            //Заголовок рівня
            Text(
              levelData.title,
              style: TextStyleHelper.instance.title18Bold.copyWith(
                color: appThemeColors.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwner) ...[
              const SizedBox(height: 4),
              Text(
                'Рівень $currentLevel з ${Constants.allLevels.length}',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Опис
            Text(
              '"${levelData.description}"',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                fontStyle: FontStyle.italic,
                color: appThemeColors.primaryBlack,
              ),
              textAlign: TextAlign.center,
            ),
            if (isOwner && levelData.level != Constants.allLevels.length) ...[
              const SizedBox(height: 16),
              // Прогрес-бар
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 20,
                      decoration: BoxDecoration(
                        color: appThemeColors.backgroundLightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final double maxWidth = constraints.maxWidth;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          width: maxWidth * progress,
                          height: 20,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                appThemeColors.successGreen,
                                appThemeColors.successGreen.withAlpha(146),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        );
                      },
                    ),
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          '$userPoints / ${levelData.maxPoints}',
                          style: TextStyleHelper.instance.title13Regular
                              .copyWith(
                                color: progress > 0.46
                                    ? appThemeColors.primaryWhite
                                    : appThemeColors.primaryBlack,
                                fontWeight: FontWeight.bold,
                                shadows: progress > 0.46
                                    ? [
                                        Shadow(
                                          color: appThemeColors.primaryBlack,
                                          blurRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (nextLevel != null) ...[
                Text(
                  '$pointsToNext балів до наступного рівня',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
            if (levelData.level == Constants.allLevels.length && isOwner) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: appThemeColors.blueMixedColor.withAlpha(146),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: appThemeColors.blueMixedColor),
                ),
                child: Text(
                  'Максимальний рівень досягнуто!',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
