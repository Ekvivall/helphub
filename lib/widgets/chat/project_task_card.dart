import 'package:flutter/material.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/organization_model.dart';
import '../../models/project_application_model.dart';
import '../../models/volunteer_model.dart';
import '../../routes/app_router.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/chat/chat_view_model.dart';
import '../user_avatar_with_frame.dart';

class ProjectTaskCard extends StatelessWidget {
  final ProjectTaskModel task;
  final bool isOrganizer;
  final String projectId;
  final bool isAssignedToCurrentUser;
  final List<ProjectApplicationModel> applications;

  const ProjectTaskCard({
    super.key,
    required this.task,
    required this.isOrganizer,
    required this.projectId,
    required this.isAssignedToCurrentUser,
    this.applications = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatViewModel>(
      builder: (context, viewModel, child) {
        // Відображаємо різні картки для виконаних та не виконаних завдань
        if (task.status == TaskStatus.confirmed) {
          return _buildCompletedTaskCard(viewModel);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: appThemeColors.backgroundLightGrey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTaskInfo(viewModel),
              const SizedBox(height: 12),
              if (isOrganizer)
                _buildOrganizerActions(context, viewModel)
              else
                _buildVolunteerActions(context, viewModel),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompletedTaskCard(ChatViewModel viewModel) {
    final assignedVolunteers = task.assignedVolunteerIds!
        .map((id) => viewModel.getVolunteerProfile(id))
        .where((profile) => profile != null)
        .toList();

    String namesList = 'Невідомий користувач';
    if (assignedVolunteers.isNotEmpty) {
      namesList = assignedVolunteers
          .map((profile) {
            if (profile is VolunteerModel) {
              return profile.fullName ?? profile.displayName ?? 'Волонтер';
            } else if (profile is OrganizationModel) {
              return profile.organizationName ?? 'Фонд';
            }
            return 'Невідомий користувач';
          })
          .join(', ');
    }

    final formattedDate = task.completionDate != null
        ? DateFormat('dd MMMM', 'uk').format(task.completionDate!)
        : 'невідомо';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  task.title ?? 'Назва завдання',
                  style: TextStyleHelper.instance.title18Bold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Виконано',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.successGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Викона${assignedVolunteers.length > 1 ? 'ли' : 'в'}: $namesList',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'виконано $formattedDate',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.textMediumGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskInfo(ChatViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                task.title ?? 'Назва завдання',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStatusText(task.status),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          task.description ?? 'Опис завдання',
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
          ),
        ),
        const SizedBox(height: 6),
        if (task.status == TaskStatus.pending ||
            task.status == TaskStatus.inProgress)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildResponsibleInfo(viewModel)),
              Text(
                'до ${DateFormat('dd MMMM', 'uk').format(task.deadline!)}',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildResponsibleInfo(ChatViewModel viewModel) {
    if (task.status == TaskStatus.inProgress &&
        task.assignedVolunteerIds?.isNotEmpty == true) {
      final assignedVolunteers = task.assignedVolunteerIds!
          .map((id) => viewModel.getVolunteerProfile(id))
          .where((profile) => profile != null)
          .toList();
      String namesList = 'Невідомий користувач';
      if (assignedVolunteers.isNotEmpty) {
        namesList = assignedVolunteers
            .map((profile) {
              if (profile is VolunteerModel) {
                return profile.fullName ?? profile.displayName ?? 'Волонтер';
              } else if (profile is OrganizationModel) {
                return profile.organizationName ?? 'Фонд';
              }
              return 'Невідомий користувач';
            })
            .join(', ');
      }
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            'Відповідальн${assignedVolunteers.length > 1 ? 'i' : 'ий'}: $namesList',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.primaryBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (task.neededPeople! - assignedVolunteers.length > 0 &&
              (task.status == TaskStatus.pending ||
                  task.status == TaskStatus.inProgress))
            Text(
              'Ще потрібно ${task.neededPeople! - assignedVolunteers.length} відповідальних',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.errorRed,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.left,
            ),
        ],
      );
    }
    return Text(
      'Потрібно ${task.neededPeople} відповідальних',
      style: TextStyleHelper.instance.title14Regular.copyWith(
        color: appThemeColors.errorRed,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildStatusText(TaskStatus? status) {
    Color color;
    String text;
    switch (status) {
      case TaskStatus.inProgress:
        color = appThemeColors.blueAccent;
        text = 'Виконується';
        break;
      case TaskStatus.completed:
        color = appThemeColors.successGreen;
        text = 'Виконано';
        break;
      default:
        color = appThemeColors.errorRed;
        text = 'Відкрито';
        break;
    }
    return Text(
      text,
      style: TextStyleHelper.instance.title16Bold.copyWith(color: color),
    );
  }

  Widget _buildOrganizerActions(BuildContext context, ChatViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (applications.isNotEmpty)
          _buildOrganizerApplications(context, viewModel),
        if (task.status == TaskStatus.completed)
          _buildOrganizerConfirmationBlock(context, viewModel),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isAssignedToCurrentUser &&
                task.status == TaskStatus.inProgress) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.markTaskAsCompleted(
                      projectId: projectId,
                      task: task,
                      volunteerId: viewModel.currentUserId,
                    );
                  },
                  style: _actionButtonStyle(
                    bgColor: appThemeColors.successGreen,
                  ),
                  child: const Text(
                    'Виконати завдання',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(width: 26),
            ],
            if ((task.assignedVolunteerIds == null ||
                    task.assignedVolunteerIds!.length < task.neededPeople! &&
                        !task.assignedVolunteerIds!.contains(
                          viewModel.currentUserId,
                        )) &&
                (task.status == TaskStatus.pending ||
                    task.status == TaskStatus.inProgress))
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    viewModel.assignSelfToTask(task: task);
                  },
                  style: _actionButtonStyle(),
                  child: const Text(
                    'Призначити себе',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(width: 8),
          ],
        ),
      ],
    );
  }

  Widget _buildVolunteerActions(BuildContext context, ChatViewModel viewModel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isAssignedToCurrentUser &&
            task.status == TaskStatus.inProgress) ...[
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                viewModel.markTaskAsCompleted(
                  projectId: projectId,
                  task: task,
                  volunteerId: viewModel.currentUserId,
                );
              },
              style: _actionButtonStyle(
                bgColor: appThemeColors.successGreen,
                textColor: appThemeColors.primaryWhite,
              ),
              child: const Text(
                'Виконати завдання',
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 26),
        ],
        if (!isAssignedToCurrentUser &&
            (task.assignedVolunteerIds == null ||
                task.assignedVolunteerIds!.length < task.neededPeople!) &&
            (task.status == TaskStatus.pending ||
                task.status == TaskStatus.inProgress))
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  AppRoutes.applyToProjectScreen,
                  arguments: projectId,
                );
              },
              style: _actionButtonStyle(),
              child: const Text('Подати заявку', textAlign: TextAlign.center),
            ),
          ),
        if (isAssignedToCurrentUser && task.status == TaskStatus.completed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Очікує підтвердження організатором',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.textMediumGrey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOrganizerApplications(
    BuildContext context,
    ChatViewModel viewModel,
  ) {
    if (applications.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Заявки (${applications.length}):',
          style: TextStyleHelper.instance.title16Bold.copyWith(
            color: appThemeColors.primaryBlack,
          ),
        ),
        const SizedBox(height: 6),
        ...applications.map((app) {
          final volunteerProfile = viewModel.getVolunteerProfile(
            app.volunteerId,
          );
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: appThemeColors.primaryWhite,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: appThemeColors.textMediumGrey.withAlpha(76),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    UserAvatarWithFrame(
                      size: 18,
                      photoUrl: volunteerProfile?.photoUrl,
                      role: volunteerProfile?.role,
                      uid: volunteerProfile?.uid,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            volunteerProfile is VolunteerModel
                                ? (volunteerProfile).fullName ??
                                      (volunteerProfile).displayName ??
                                      'Волонтер'
                                : volunteerProfile is OrganizationModel
                                ? (volunteerProfile).organizationName ?? 'Фонд'
                                : 'Невідомий користувач',
                            style: TextStyleHelper.instance.title16Bold
                                .copyWith(color: appThemeColors.primaryBlack),
                          ),
                          Text(
                            'м. ${volunteerProfile?.city ?? 'Невідомо'}, ${volunteerProfile is VolunteerModel ? "${(volunteerProfile).levelProgress} рівень" : ""}',
                            style: TextStyleHelper.instance.title13Regular
                                .copyWith(color: appThemeColors.textMediumGrey),
                          ),
                          Text(
                            '${volunteerProfile?.projectsCount} проєктів, ${volunteerProfile?.eventsCount} події',
                            style: TextStyleHelper.instance.title13Regular
                                .copyWith(color: appThemeColors.textMediumGrey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: appThemeColors.successGreen,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        onPressed: () {
                          viewModel.handleApplication(
                            projectId: projectId,
                            task: task,
                            application: app,
                            accept: true,
                          );
                        },
                        icon: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: appThemeColors.errorRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: IconButton(
                        onPressed: () {
                          _showRejectionConfirmationDialog(
                            context,
                            () => viewModel.handleApplication(
                              projectId: projectId,
                              task: task,
                              application: app,
                              accept: false,
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ],
                ),
                if (app.message != null && app.message!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      app.message!,
                      style: TextStyleHelper.instance.title14Regular.copyWith(
                        color: appThemeColors.primaryBlack,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrganizerConfirmationBlock(
    BuildContext context,
    ChatViewModel viewModel,
  ) {
    final volunteerProfile = viewModel.getVolunteerProfile(
      task.completedByVolunteerId!,
    );
    String name = volunteerProfile is VolunteerModel
        ? (volunteerProfile).fullName ??
              (volunteerProfile).displayName ??
              'Волонтер'
        : volunteerProfile is OrganizationModel
        ? (volunteerProfile).organizationName ?? 'Фонд'
        : 'Невідомий користувач';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Волонтер $name відмітив завдання як виконане. Підтвердити?',
          style: TextStyleHelper.instance.title14Regular,
        ),
        Row(
          children: [
            IconButton(
              onPressed: () {
                if (viewModel.currentUserId == viewModel.project?.organizerId) {
                  viewModel.confirmTaskCompletion(
                    projectId: projectId,
                    task: task,
                  );
                } else {
                  viewModel.markTaskAsCompleted(
                    projectId: projectId,
                    task: task,
                    volunteerId: viewModel.currentUserId,
                  );
                }
              },
              icon: Icon(Icons.check, color: appThemeColors.successGreen),
            ),
            IconButton(
              onPressed: () {
                viewModel.rejectTaskCompletion(
                  projectId: projectId,
                  task: task,
                );
              },
              icon: Icon(Icons.close, color: appThemeColors.errorRed),
            ),
          ],
        ),
      ],
    );
  }

  ButtonStyle _actionButtonStyle({Color? bgColor, Color? textColor}) {
    return ElevatedButton.styleFrom(
      backgroundColor: bgColor ?? appThemeColors.blueAccent,
      foregroundColor: textColor ?? appThemeColors.primaryWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  void _showRejectionConfirmationDialog(
    BuildContext context,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Відхилити заявку?'),
          content: const Text(
            'Ви впевнені, що хочете відхилити цю заявку? Цю дію не можна буде скасувати.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Скасувати',
                style: TextStyle(color: appThemeColors.primaryBlack),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                onConfirm();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.errorRed,
              ),
              child: Text(
                'Відхилити',
                style: TextStyle(color: appThemeColors.primaryWhite),
              ),
            ),
          ],
        );
      },
    );
  }
}
