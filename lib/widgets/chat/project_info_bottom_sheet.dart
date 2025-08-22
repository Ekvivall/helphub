import 'package:flutter/material.dart';
import 'package:helphub/models/project_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';

class ProjectInfoBottomSheet extends StatelessWidget {
  final ProjectModel project;

  const ProjectInfoBottomSheet({
    super.key,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      builder: (context, scrollController) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: appThemeColors.grey200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              project.title ?? 'Без назви',
              style: TextStyleHelper.instance.title20Regular.copyWith(
                color: appThemeColors.primaryBlack, fontWeight: FontWeight.w900
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  if (project.description != null && project.description!.isNotEmpty)
                    _buildSection(
                      title: 'Опис',
                      content: project.description!,
                    ),
                  if (project.startDate != null && project.endDate != null)
                    _buildSection(
                      title: 'Тривалість',
                      content:
                      '${project.startDate!.day}.${project.startDate!.month}.${project.startDate!.year} — ${project.endDate!.day}.${project.endDate!.month}.${project.endDate!.year}',
                    ),
                  if (project.tasks != null && project.tasks!.isNotEmpty)
                    _buildSection(
                      title: 'Кількість завдань',
                      content: '${project.tasks!.length}',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
        ],
      ),
    );
  }
}
