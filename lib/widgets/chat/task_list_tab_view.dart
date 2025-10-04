import 'package:flutter/material.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/chat/chat_task_view_model.dart';
import 'package:helphub/widgets/chat/project_task_card.dart';
import 'package:provider/provider.dart';

import '../../data/models/project_task_model.dart';

enum TaskDisplayFilter { all, my, completed }

class TaskListTabView extends StatefulWidget {
  final ChatTaskViewModel viewModel;

  const TaskListTabView({super.key, required this.viewModel});

  @override
  State<TaskListTabView> createState() => _TaskListTabViewState();
}

class _TaskListTabViewState extends State<TaskListTabView> {
  TaskDisplayFilter _displayFilter = TaskDisplayFilter.all;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Перемикач фільтрів "Усі", "Мої", "Виконані"
        _buildDisplayFilterToggle(context),
        const SizedBox(height: 6),
        // Основний контент (список завдань)
        Expanded(
          child: Consumer<ChatTaskViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return Center(
                  child: CircularProgressIndicator(
                    color: appThemeColors.successGreen,
                  ),
                );
              }

              final tasks = _getFilteredTaskList(viewModel);

              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    _getEmptyListMessage(),
                    textAlign: TextAlign.center,
                    style: TextStyleHelper.instance.title16Regular.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                    ),
                  ),
                );
              }

              return _buildTaskListWithHeaders(tasks, viewModel);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskListWithHeaders(
    List<ProjectTaskModel> tasks,
    ChatTaskViewModel viewModel,
  ) {
    final groupedTasks = _groupTasksByStatus(tasks);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _calculateTotalItems(groupedTasks),
      itemBuilder: (context, index) {
        return _buildItemAtIndex(index, groupedTasks, viewModel);
      },
    );
  }

  Map<String, List<ProjectTaskModel>> _groupTasksByStatus(
    List<ProjectTaskModel> tasks,
  ) {
    final Map<String, List<ProjectTaskModel>> grouped = {};

    for (final task in tasks) {
      String groupKey;
      switch (task.status) {
        case TaskStatus.pending:
        case TaskStatus.inProgress:
        case TaskStatus.completed:
          groupKey = 'planned';
          break;
        case TaskStatus.confirmed:
          groupKey = 'completed';
          break;
      }

      if (grouped[groupKey] == null) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(task);
    }

    return grouped;
  }

  int _calculateTotalItems(Map<String, List<ProjectTaskModel>> groupedTasks) {
    int total = 0;

    if (groupedTasks['planned']?.isNotEmpty == true) {
      total += 1; // заголовок
      total += groupedTasks['planned']!.length; // завдання
    }

    if (groupedTasks['completed']?.isNotEmpty == true) {
      total += 1; // заголовок
      total += groupedTasks['completed']!.length; // завдання
    }

    return total;
  }

  Widget _buildItemAtIndex(
    int index,
    Map<String, List<ProjectTaskModel>> groupedTasks,
    ChatTaskViewModel viewModel,
  ) {
    int currentIndex = 0;

    final plannedTasks = groupedTasks['planned'] ?? [];
    if (plannedTasks.isNotEmpty) {
      if (index == currentIndex) {
        return _buildSectionHeader('Заплановані завдання');
      }
      currentIndex++;

      if (index < currentIndex + plannedTasks.length) {
        final taskIndex = index - currentIndex;
        return _buildTaskCard(plannedTasks[taskIndex], viewModel);
      }
      currentIndex += plannedTasks.length;
    }

    final completedTasks = groupedTasks['completed'] ?? [];
    if (completedTasks.isNotEmpty) {
      if (index == currentIndex) {
        return _buildSectionHeader('Виконані завдання');
      }
      currentIndex++;

      if (index < currentIndex + completedTasks.length) {
        final taskIndex = index - currentIndex;
        return _buildTaskCard(completedTasks[taskIndex], viewModel);
      }
    }

    return const SizedBox(); // Fallback
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyleHelper.instance.title18Bold.copyWith(
          color: appThemeColors.backgroundLightGrey,
        ),
      ),
    );
  }

  Widget _buildTaskCard(ProjectTaskModel task, ChatTaskViewModel viewModel) {
    final applications = viewModel.getApplicationsForTask(task.id!);
    final bool isAssignedToCurrentUser =
        task.assignedVolunteerIds?.contains(viewModel.currentUserId) ?? false;

    return ProjectTaskCard(
      task: task,
      isAssignedToCurrentUser: isAssignedToCurrentUser,
      applications: applications,
      projectId: viewModel.project!.id!,
      isOrganizer: viewModel.project?.organizerId == viewModel.currentUserId,
    );
  }

  // Helper-метод для отримання відфільтрованого списку
  List<ProjectTaskModel> _getFilteredTaskList(ChatTaskViewModel viewModel) {
    switch (_displayFilter) {
      case TaskDisplayFilter.all:
        return viewModel.allTasks;
      case TaskDisplayFilter.my:
        return viewModel.myTasks;
      case TaskDisplayFilter.completed:
        return viewModel.completedTasks;
    }
  }

  // Helper-метод для повідомлення про порожній список
  String _getEmptyListMessage() {
    switch (_displayFilter) {
      case TaskDisplayFilter.all:
        return 'Завдань у проєкті ще немає.';
      case TaskDisplayFilter.my:
        return 'У вас немає призначених завдань.';
      case TaskDisplayFilter.completed:
        return 'У цьому проєкті ще немає завершених завдань.';
    }
  }

  Widget _buildDisplayFilterToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25)),
      child: Row(
        children: [
          Expanded(
            child: _buildFilterButton(
              text: 'Усі завдання',
              isSelected: _displayFilter == TaskDisplayFilter.all,
              onTap: () => setState(() {
                _displayFilter = TaskDisplayFilter.all;
              }),
            ),
          ),
          Expanded(
            child: _buildFilterButton(
              text: 'Мої завдання',
              isSelected: _displayFilter == TaskDisplayFilter.my,
              onTap: () => setState(() {
                _displayFilter = TaskDisplayFilter.my;
              }),
            ),
          ),
          Expanded(
            child: _buildFilterButton(
              text: 'Виконані',
              isSelected: _displayFilter == TaskDisplayFilter.completed,
              onTap: () => setState(() {
                _displayFilter = TaskDisplayFilter.completed;
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? appThemeColors.primaryWhite
              : appThemeColors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: appThemeColors.primaryBlack.withAlpha(76),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: isSelected
                ? appThemeColors.primaryBlack
                : appThemeColors.primaryWhite,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
