import 'package:flutter/material.dart';
import 'package:helphub/core/services/project_service.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/project_model.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/profile/category_chip_widget.dart';
import 'package:helphub/widgets/profile/report_section_widget.dart';
import 'package:intl/intl.dart';

import '../../models/project_task_model.dart';
import '../../views/chat/chat_project_screen.dart';
import '../custom_elevated_button.dart';

class ProjectOrganizationActivityItem extends StatelessWidget {
  final ActivityModel activity;
  final bool isOwner;

  const ProjectOrganizationActivityItem({
    super.key,
    required this.activity,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final ProjectService projectService = ProjectService();

    return FutureBuilder<ProjectModel?>(
      future: projectService.getProjectById(activity.entityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Не вдалося завантажити деталі організованого проєкту: ${snapshot.error ?? "Проєкт не знайдений"}',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
          );
        }

        final ProjectModel project = snapshot.data!;
        // Перевіряємо, чи проєкт вже завершився
        final totalTasks = project.tasks?.length;
        final completedTasks = project.tasks
            ?.where((t) => t.status == TaskStatus.confirmed)
            .length;
        final bool isProjectFinished =
            project.endDate!.isBefore(DateTime.now()) ||
            totalTasks == completedTasks;

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        project.title!, // Назва проєкту
                        style: TextStyleHelper.instance.title18Bold.copyWith(
                          color: appThemeColors.primaryBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isOwner)
                      IconButton(
                        icon: Icon(
                          Icons.chat_bubble_outline,
                          color: appThemeColors.blueAccent,
                        ),
                        onPressed: () {
                          Navigator.of(context).pushNamed(
                            AppRoutes.chatProjectScreen,
                            arguments: {
                              'projectId': project.id,
                              'displayMode': DisplayMode.chat,
                            },
                          );
                        },
                      ),
                  ],
                ),
                // Категорії
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: project.categories!
                      .map((category) => CategoryChipWidget(chip: category))
                      .toList(),
                ),
                const SizedBox(height: 4),
                // Статус "Організатор"
                _buildInfoRow(
                  icon: Icons.business_center_outlined,
                  text: 'Організатор',
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(height: 4),
                // Дати проєкту
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  text: project.startDate != null && project.endDate != null
                      ? '${DateFormat('dd.MM.yyyy').format(project.startDate!)} - ${DateFormat('dd.MM.yyyy').format(project.endDate!)}'
                      : 'Дати не вказано',
                  color: appThemeColors.textMediumGrey,
                ),
                const SizedBox(height: 4),
                // Місце
                _buildInfoRow(
                  icon: Icons.location_on,
                  text: project.locationText ?? 'Місце не вказано',
                  color: appThemeColors.textMediumGrey,
                ),
                if (isOwner) ...[
                  const SizedBox(height: 8),
                  // Кнопки дій
                  if (!isProjectFinished) ...[
                    Row(
                      children: [
                        Expanded(
                          child: CustomElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.chatProjectScreen,
                                arguments: {
                                  'projectId': project.id,
                                  'displayMode': DisplayMode.tasks,
                                },
                              );
                            },
                            backgroundColor: appThemeColors.successGreen,
                            borderRadius: 8,
                            height: 34,
                            text: 'Список завдань',
                            textStyle: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: appThemeColors.primaryWhite,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushNamed(
                                AppRoutes.createProjectScreen,
                                arguments: project.id,
                              );
                            },
                            backgroundColor: appThemeColors.blueAccent,
                            borderRadius: 8,
                            height: 34,
                            text: 'Редагувати',
                            textStyle: TextStyleHelper.instance.title14Regular
                                .copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: appThemeColors.primaryWhite,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ] else // Проєкт завершений
                    buildReportSection(
                      project.reportId,
                      activity,
                      context,
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color ?? appThemeColors.textMediumGrey),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: color ?? appThemeColors.textMediumGrey,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
