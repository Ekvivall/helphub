import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/admin/admin_view_model.dart';
import 'package:provider/provider.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

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
          'Адміністративна панель',
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
        child: Consumer<AdminViewModel>(
          builder: (context, viewModel, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStats(context, viewModel),
                  const SizedBox(height: 24),
                  Text(
                    'Модулі управління',
                    style: TextStyleHelper.instance.title20Regular.copyWith(
                      fontWeight: FontWeight.w800,
                      color: appThemeColors.backgroundLightGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleCard(
                    context,
                    'Перевірка фондів',
                    'Керування заявками на верифікацію',
                    Icons.verified_user,
                    appThemeColors.lightGreenColor,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminVerificationsScreen);
                    },
                    badge: viewModel.pendingVerifications.length,
                  ),
                  const SizedBox(height: 12),
                  _buildModuleCard(
                    context,
                    'Центр підтримки',
                    'Відповіді на звернення користувачів',
                    Icons.support_agent,
                    appThemeColors.blueAccent,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminSupportScreen);
                    },
                    badge: viewModel.openTickets.length,
                  ),
                  const SizedBox(height: 12),
                  _buildModuleCard(
                    context,
                    "Зворотній зв'язок",
                    'Перегляд відгуків користувачів',
                    Icons.feedback,
                    appThemeColors.orangeAccent,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminFeedbackScreen);
                    },
                    badge: viewModel.unreadFeedbackCount,
                  ),
                  const SizedBox(height: 12),
                  _buildModuleCard(
                    context,
                    'Статистика',
                    'Аналітика та звіти',
                    Icons.analytics,
                    appThemeColors.purpleColor,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminStatisticsScreen);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModuleCard(
                    context,
                    'Волонтери',
                    'Пошук та перегляд волонтерів',
                    Icons.people,
                    appThemeColors.cyanAccent,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminVolunteersScreen);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildModuleCard(
                    context,
                    'Турнірні сезони',
                    'Управління медалями та сезонами',
                    Icons.emoji_events,
                    appThemeColors.goldColor,
                    () {
                      Navigator.of(
                        context,
                      ).pushNamed(AppRoutes.adminTournamentScreen);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, AdminViewModel viewModel) {
    if (viewModel.isLoadingStatistics) {
      return Center(
        child: CircularProgressIndicator(
          color: appThemeColors.backgroundLightGrey,
        ),
      );
    }
    if (viewModel.statistics == null) {
      return const SizedBox.shrink();
    }
    final stats = viewModel.statistics!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Коротка статистика',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Волонтери',
                stats.totalVolunteers.toString(),
                Icons.people,
              ),
              _buildStatItem(
                'Фонди',
                stats.totalOrganizations.toString(),
                Icons.business,
              ),
              _buildStatItem(
                'Події',
                stats.totalEvents.toString(),
                Icons.event,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Проєкти',
                stats.totalProjects.toString(),
                Icons.work,
              ),
              _buildStatItem(
                'Збори',
                stats.totalFundraisings.toString(),
                Icons.volunteer_activism,
              ),
              _buildStatItem(
                'Активні користувачі',
                stats.activeUsers.toString(),
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return SizedBox(
      width: 80,
      child: Column(
        children: [
          Icon(icon, color: appThemeColors.blueAccent, size: 28),
          const SizedBox(height: 4),
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
              color: appThemeColors.textMediumGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int? badge,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(230),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withAlpha(85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyleHelper.instance.title16Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyleHelper.instance.title13Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null && badge > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: appThemeColors.errorRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge.toString(),
                      style: TextStyleHelper.instance.title13Regular.copyWith(
                        color: appThemeColors.primaryWhite,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: appThemeColors.textMediumGrey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
