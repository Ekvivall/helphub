import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/data/models/user_achievement_model.dart';
import 'package:helphub/data/services/achievement_service.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/profile/achievement_item.dart';
import 'package:provider/provider.dart';

class AllAchievementsScreen extends StatefulWidget {
  const AllAchievementsScreen({super.key});

  @override
  State<AllAchievementsScreen> createState() => _AllAchievementsScreenState();
}

class _AllAchievementsScreenState extends State<AllAchievementsScreen> {
  final AchievementService _achievementService = AchievementService();

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          backgroundColor: appThemeColors.blueAccent,
          appBar: AppBar(
            backgroundColor: appThemeColors.appBarBg,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                size: 40,
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            title: Text(
              'Досягнення',
              style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.9, -0.4),
                end: const Alignment(-0.9, 0.4),
                colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
              ),
            ),
            child: _buildBody(viewModel),
          ),
        );
      },
    );
  }

  Widget _buildBody(ProfileViewModel viewModel) {
    if (viewModel.user == null) {
      return Center(
        child: CircularProgressIndicator(color: appThemeColors.primaryWhite),
      );
    }

    final userId = viewModel.user!.uid!;
    return StreamBuilder<List<UserAchievementModel>>(
      stream: _achievementService.getUserAchievements(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: appThemeColors.primaryWhite,
            ),
          );
        }
        final userAchievements = snapshot.data ?? [];
        final allAchievements = Constants.allAchievements;

        final Map<String, UserAchievementModel> userAchievementsMap = {
          for (var ua in userAchievements) ua.achievementId: ua,
        };
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Статистика
              _buildProgressCard(
                userAchievements.length,
                allAchievements.length,
              ),
              const SizedBox(height: 24),
              Text(
                'Всі досягнення',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.backgroundLightGrey,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: allAchievements.length,
                itemBuilder: (context, index) {
                  final achievement = allAchievements[index];
                  final userAchievement = userAchievementsMap[achievement.id];
                  final isUnlocked = userAchievement != null;
                  return AchievementItemWidget(
                    achievement: achievement,
                    isUnlocked: isUnlocked,
                    unlockedAt: userAchievement?.unlockedAt,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressCard(int unlocked, int total) {
    final percentage = total > 0 ? (unlocked / total * 100).round() : 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Прогрес',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: appThemeColors.lightGreenColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unlocked/$total',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.lightGreenColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Прогрес бар
          Stack(
            children: [
              Container(
                width: double.infinity,
                height: 12,
                decoration: BoxDecoration(
                  color: appThemeColors.grey200,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        appThemeColors.lightGreenColor,
                        appThemeColors.successGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$percentage% завершено',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
          ),
          if (percentage == 100) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: appThemeColors.lightGreenColor.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: appThemeColors.lightGreenColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Вітаємо! Всі досягнення отримано!',
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: appThemeColors.lightGreenColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
