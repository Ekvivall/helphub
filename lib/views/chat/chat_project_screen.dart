import 'package:flutter/material.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:helphub/view_models/chat/chat_view_model.dart';
import 'package:provider/provider.dart';

import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/chat/chat_task_view_model.dart';
import '../../widgets/chat/task_list_tab_view.dart';

enum DisplayMode { chat, tasks }

class ChatProjectScreen extends StatefulWidget {
  final String chatId;
  final DisplayMode initialDisplayMode;

  const ChatProjectScreen({
    super.key,
    required this.chatId,
    required this.initialDisplayMode,
  });

  @override
  State<ChatProjectScreen> createState() => _ChatProjectScreenState();
}

class _ChatProjectScreenState extends State<ChatProjectScreen> {
  late DisplayMode _displayMode;
  late ChatViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = Provider.of<ChatViewModel>(context, listen: false);
    _viewModel.openChat(widget.chatId);
    _displayMode = widget.initialDisplayMode;
    ChatTaskViewModel chatTaskViewModel = Provider.of<ChatTaskViewModel>(context, listen: false);
    chatTaskViewModel.listenToProjectTasks(_viewModel.currentChat!.entityId!);
    _displayMode = widget.initialDisplayMode;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatTaskViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading && viewModel.project == null) {
          return Center(
            child: CircularProgressIndicator(
              color: appThemeColors.successGreen,
            ),
          );
        }
        final totalNeededPeople = viewModel.project?.tasks
            ?.map((task) => task.neededPeople ?? 0)
            .fold<int>(0, (sum, count) => sum + count);
        final totalVolunteers = viewModel.project?.tasks
            ?.map((task) => task.assignedVolunteerIds?.length ?? 0)
            .fold<int>(0, (sum, count) => sum + count);
        return Scaffold(
          backgroundColor: appThemeColors.blueAccent,
          appBar: AppBar(
            backgroundColor: appThemeColors.appBarBg,
            leading: IconButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: Icon(
                Icons.arrow_back,
                size: 40,
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.project?.title ?? '',
                  style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                Text(
                  '${totalVolunteers ?? 0}/${totalNeededPeople ?? 0} учасників',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.textLightColor,
                  ),
                ),
              ],
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(0.9, -0.4),
                end: Alignment(-0.9, 0.4),
                colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
              ),
            ),
            child: Column(
              children: [
                _buildStatusInfoBar(context, viewModel),
                _buildDisplayModeToggle(context),
                const SizedBox(height: 8),
                Expanded(
                  child: _displayMode == DisplayMode.chat
                      ? Center(
                          child: Text(
                            'Тут буде віджет чату',
                            style: TextStyleHelper.instance.title16Regular
                                .copyWith(
                                  color: appThemeColors.backgroundLightGrey,
                                ),
                          ),
                        )
                      : TaskListTabView(viewModel: viewModel),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDisplayModeToggle(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: appThemeColors.grey100, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _displayMode = DisplayMode.chat;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _displayMode == DisplayMode.chat
                      ? appThemeColors.blueMixedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Чат',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _displayMode == DisplayMode.chat
                          ? appThemeColors.primaryBlack
                          : appThemeColors.textMediumGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _displayMode = DisplayMode.tasks;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _displayMode == DisplayMode.tasks
                      ? appThemeColors.blueMixedColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    'Завдання',
                    style: TextStyleHelper.instance.title16Bold.copyWith(
                      fontWeight: FontWeight.w700,
                      color: _displayMode == DisplayMode.tasks
                          ? appThemeColors.primaryBlack
                          : appThemeColors.textMediumGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusInfoBar(BuildContext context, ChatTaskViewModel viewModel) {
    final project = viewModel.project;
    if (project == null) return const SizedBox.shrink();

    // Розрахунок прогресу
    final totalTasks = project.tasks?.length;
    final completedTasks = project.tasks
        ?.where((t) => t.status == TaskStatus.confirmed)
        .length;
    final double progress = totalTasks! > 0
        ? completedTasks! / totalTasks
        : 0.0;

    // Розрахунок кількості днів до завершення
    final daysLeft = project.endDate?.difference(DateTime.now()).inDays;
    String daysLeftText;
    if (daysLeft! < 0) {
      daysLeftText = 'Проєкт завершено';
    } else if (daysLeft == 1) {
      daysLeftText = '$daysLeft день до завершення';
    } else {
      daysLeftText = '$daysLeft дні до завершення';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusItem(
                Icons.check_circle_outline_rounded,
                'Виконано: ${project.tasks?.where((t) => t.status == TaskStatus.confirmed).length}/${project.tasks?.length} завдань',
              ),
              _buildStatusItem(Icons.calendar_today_outlined, daysLeftText),
            ],
          ),
          const SizedBox(height: 12),
          _buildProgressBar(progress),
        ],
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: appThemeColors.backgroundLightGrey, size: 16),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyleHelper.instance.title13Regular.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double progress) {
    return Container(
      alignment: Alignment.centerLeft,
      height: 8,
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey.withAlpha(76),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: appThemeColors.successGreen,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
