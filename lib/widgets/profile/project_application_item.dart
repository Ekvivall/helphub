import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/project_application_model.dart';
import 'package:helphub/models/project_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:intl/intl.dart';

import '../../routes/app_router.dart';
import '../../views/chat/chat_project_screen.dart';
import '../custom_elevated_button.dart';

class ProjectApplicationItem extends StatelessWidget {
  final ProjectApplicationModel application;
  final ProjectModel? project;

  const ProjectApplicationItem({
    super.key,
    required this.application,
    required this.project,
  });

  @override
  Widget build(BuildContext context) {
    if (project == null) {
      return const SizedBox();
    }

    final task = project!.tasks?.firstWhere((t) => t.id == application.taskId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: appThemeColors.blueMixedColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project!.title ?? 'Назва проєкту',
            style: TextStyleHelper.instance.title18Bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          if (task != null)
            Text(
              'Завдання: ${task.title}',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryBlack,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Статус:',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              _buildStatusText(application.status),
            ],
          ),
          const SizedBox(height: 8),
          // Додаємо супровідне повідомлення
          if (application.message != null && application.message!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ваше повідомлення:',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                ExpandableText(
                  application.message!,
                  expandText: 'докладніше',
                  collapseText: 'згорнути',
                  maxLines: 2,
                  linkColor: appThemeColors.blueAccent,
                  style: TextStyleHelper.instance.title13Regular.copyWith(
                    color: appThemeColors.primaryBlack.withAlpha(175),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          Text(
            'Відправлено: ${DateFormat('dd.MM.yyyy').format(application.timestamp.toDate())}',
            style: TextStyleHelper.instance.title13Regular.copyWith(
              color: appThemeColors.primaryBlack.withAlpha(175),
            ),
          ),
          if (application.status == 'approved')
            CustomElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.chatProjectScreen,
                  arguments: {
                    'projectId': project?.id,
                    'displayMode': DisplayMode.tasks,
                  },
                );
              },
              backgroundColor: appThemeColors.blueAccent,
              borderRadius: 8,
              height: 34,
              text: 'Список завдань',
              textStyle: TextStyleHelper.instance.title14Regular.copyWith(
                fontWeight: FontWeight.w700,
                color: appThemeColors.primaryWhite,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(String? status) {
    Color statusColor = appThemeColors.primaryBlack;
    String statusText = 'Невідомий';

    if (status == 'pending') {
      statusText = 'На розгляді';
      statusColor = appThemeColors.blueAccent;
    } else if (status == 'approved') {
      statusText = 'Схвалено';
      statusColor = appThemeColors.successGreen;
    } else if (status == 'rejected') {
      statusText = 'Відхилено';
      statusColor = appThemeColors.errorRed;
    }

    return Text(
      statusText,
      style: TextStyleHelper.instance.title14Regular.copyWith(
        color: statusColor,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
