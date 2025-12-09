import 'package:flutter/material.dart';
import 'package:helphub/data/models/admin_statistics_model.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/admin/admin_view_model.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:provider/provider.dart';

import '../../routes/app_router.dart';

class AdminStatisticsScreen extends StatelessWidget {
  const AdminStatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
          'Статистика',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              context.read<AdminViewModel>().loadStatistics();
            },
            icon: Icon(
              Icons.refresh,
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ],
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
        child: Consumer<AdminViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoadingStatistics) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.backgroundLightGrey,
                ),
              );
            }
            if (viewModel.statisticsError != null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: appThemeColors.errorRed,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        viewModel.statisticsError!,
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.title16Regular.copyWith(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (viewModel.statistics == null) {
              return const SizedBox.shrink();
            }
            final stats = viewModel.statistics!;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Загальна статистика
                  _buildGeneralStats(stats),
                  const SizedBox(height: 24),
                  _buildUserStats(stats),
                  const SizedBox(height: 24),
                  _buildEventsChart(stats),
                  const SizedBox(height: 24),
                  _buildProjectsChart(stats),
                  const SizedBox(height: 24),
                  _buildTopVolunteers(context, stats),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGeneralStats(AdminStatisticsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Загальна статистика',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Волонтери',
                  stats.totalVolunteers.toString(),
                  Icons.people,
                  appThemeColors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Фонди',
                  stats.totalOrganizations.toString(),
                  Icons.business,
                  appThemeColors.purpleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Події',
                  stats.totalEvents.toString(),
                  Icons.event,
                  appThemeColors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Проєкти',
                  stats.totalProjects.toString(),
                  Icons.work,
                  appThemeColors.cyanAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatCard(
            'Збори коштів',
            stats.totalFundraisings.toString(),
            Icons.volunteer_activism,
            appThemeColors.successGreen,
            fullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyleHelper.instance.title20Regular.copyWith(
                    fontWeight: FontWeight.w800,
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                Text(
                  label,
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserStats(AdminStatisticsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Активність користувачів',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          _buildUserStatRow(
            'Активні користувачі (30 днів)',
            stats.activeUsers.toString(),
            Icons.trending_up,
            appThemeColors.successGreen,
          ),
          const SizedBox(height: 12),
          _buildUserStatRow(
            'Нові користувачі (цей місяць)',
            stats.newUsersThisMonth.toString(),
            Icons.person_add,
            appThemeColors.lightGreenColor,
          ),
        ],
      ),
    );
  }

  Widget _buildUserStatRow(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(85),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyleHelper.instance.title20Regular.copyWith(
                    fontWeight: FontWeight.w800,
                    color: appThemeColors.primaryBlack,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsChart(AdminStatisticsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Події за місяцями',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          _buildSimpleBarChart(
            stats.eventsByMonth,
            appThemeColors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleBarChart(Map<String, int> data, Color color) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Немає даних',
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
          ),
        ),
      );
    }

    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: data.entries.map((entry) {
        final double percentage = maxValue > 0 ? entry.value / maxValue : 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  entry.key,
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.textMediumGrey,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 32,
                      decoration: BoxDecoration(
                        color: appThemeColors.grey400,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: percentage,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyleHelper.instance.title13Regular
                                .copyWith(
                                  color: appThemeColors.primaryWhite,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProjectsChart(AdminStatisticsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Проєкти за місяцями',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 20),
          _buildSimpleBarChart(
            stats.projectsByMonth,
            appThemeColors.cyanAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildTopVolunteers(BuildContext context, AdminStatisticsModel stats) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Топ-10 волонтерів',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pushNamed(AppRoutes.adminVolunteersScreen);
                },
                child: Text(
                  'Всі волонтери',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.blueAccent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...stats.topVolunteers.asMap().entries.map((entry) {
            final index = entry.key;
            final volunteer = entry.value;
            return _buildVolunteerItem(index + 1, volunteer);
          }),
        ],
      ),
    );
  }

  Widget _buildVolunteerItem(int place, TopVolunteerModel volunteer) {
    Color placeColor;
    if (place == 1) {
      placeColor = appThemeColors.goldColor;
    } else if (place == 2) {
      placeColor = appThemeColors.textMediumGrey;
    } else if (place == 3) {
      placeColor = Colors.brown;
    } else {
      placeColor = appThemeColors.blueAccent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: appThemeColors.blueMixedColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: placeColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  place.toString(),
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryWhite,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            UserAvatarWithFrame(
              size: 20,
              role: UserRole.volunteer,
              uid: volunteer.uid,
              photoUrl: volunteer.photoUrl,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    volunteer.name,
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.primaryBlack,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${volunteer.projectsCount} проєктів • ${volunteer.eventsCount} подій',
                    style: TextStyleHelper.instance.title13Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: appThemeColors.successGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${volunteer.points} б.',
                style: TextStyleHelper.instance.title13Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
