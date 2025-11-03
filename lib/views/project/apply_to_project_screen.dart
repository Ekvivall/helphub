import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/widgets/custom_checkbox.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/models/category_chip_model.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_task_model.dart';
import '../../data/models/volunteer_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/project/project_view_model.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/profile/category_chip_widget.dart';
import '../../widgets/user_avatar_with_frame.dart';

class ApplyToProjectScreen extends StatefulWidget {
  final String projectId;

  const ApplyToProjectScreen({super.key, required this.projectId});

  @override
  State<ApplyToProjectScreen> createState() => _ApplyToProjectScreenState();
}

class _ApplyToProjectScreenState extends State<ApplyToProjectScreen> {
  final List<ProjectTaskModel> _selectedTasks = [];
  final Map<String, TextEditingController> _messageControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProjectViewModel>(
        context,
        listen: false,
      ).loadProjectDetails(widget.projectId);
    });
  }

  @override
  void dispose() {
    _messageControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  void _toggleTaskSelection(ProjectTaskModel task) {
    setState(() {
      if (_selectedTasks.contains(task)) {
        _selectedTasks.remove(task);
        _messageControllers[task.id!]?.dispose(); // Очищаємо контролер
        _messageControllers.remove(task.id!);
      } else {
        _selectedTasks.add(task);
        _messageControllers[task.id!] =
            TextEditingController(); // Створюємо новий контролер
      }
    });
  }

  Future<void> _submitApplication() async {
    if (_selectedTasks.isEmpty) {
      Constants.showErrorMessage(
        context,
        'Будь ласка, оберіть хоча б одне завдання для участі.',
      );
      return;
    }

    final viewModel = Provider.of<ProjectViewModel>(context, listen: false);

    // Збираємо мапу з повідомленнями
    final Map<String, String> messages = {};
    for (var task in _selectedTasks) {
      messages[task.id!] = _messageControllers[task.id!]?.text.trim() ?? '';
    }

    // Передаємо мапу в ViewModel
    final String? errorMessage = await viewModel.applyToProject(
      projectId: widget.projectId,
      selectedTasks: _selectedTasks,
      messages: messages,
    );
    if (errorMessage == null) {
      Constants.showSuccessMessage(context, 'Заявку успішно надіслано!');
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Помилка: $errorMessage',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.errorRed,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Consumer<ProjectViewModel>(
          builder: (context, viewModel, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Подати заявку',
                  style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                    color: appThemeColors.backgroundLightGrey,
                  ),
                ),
                if (viewModel.currentProject != null)
                  Text(
                    viewModel.currentProject!.title!,
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textLightColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            );
          },
        ),
        toolbarHeight: 80,
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
        child: Consumer<ProjectViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading || viewModel.currentProject == null) {
              return Center(
                child: CircularProgressIndicator(
                  color: appThemeColors.blueAccent,
                ),
              );
            }
            final ProjectModel project = viewModel.currentProject!;
            final BaseProfileModel? organizer = viewModel.organizer;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Блок інформації про проєкт та організатора
                        _buildProjectAndOrganizerInfo(project, organizer),
                        const SizedBox(height: 24),

                        // Секція вибору завдань
                        Text(
                          'Оберіть завдання',
                          style: TextStyleHelper.instance.title20Regular
                              .copyWith(
                                fontWeight: FontWeight.w700,
                                color: appThemeColors.backgroundLightGrey,
                              ),
                        ),
                        const SizedBox(height: 12),
                        _buildTasksSelection(project.tasks ?? []),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  child: CustomElevatedButton(
                    isLoading: viewModel.isSubmitting,
                    onPressed: _submitApplication,
                    text: 'Надіслати заявку',
                    backgroundColor: appThemeColors.blueAccent,
                    textStyle: TextStyleHelper.instance.title16Bold.copyWith(
                      color: appThemeColors.primaryWhite,
                    ),
                    borderRadius: 10,
                    height: 48,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProjectAndOrganizerInfo(
    ProjectModel project,
    BaseProfileModel? organizer,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Теги
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (project.categories != null)
              ...project.categories!.map(
                (category) => CategoryChipWidget(
                  chip: category,
                  isSelected: false, // Always selected for display
                ),
              ),
            if (project.isOnlyFriends == true)
              CategoryChipWidget(
                chip: CategoryChipModel(
                  title: 'Приватний',
                  backgroundColor: appThemeColors.orangeAccent,
                ),
                isSelected: true,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Інформація про організатора
        if (organizer != null)
          Row(
            children: [
              UserAvatarWithFrame(
                size: 25,
                role: organizer.role,
                photoUrl: organizer.photoUrl,
                frame: (organizer is VolunteerModel) ? organizer.frame : null,
                uid: organizer.uid!,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    organizer is VolunteerModel
                        ? (organizer).fullName ??
                              (organizer).displayName ??
                              'Волонтер'
                        : organizer is OrganizationModel
                        ? (organizer).organizationName ?? 'Фонд'
                        : 'Невідомий користувач',
                    style: TextStyleHelper.instance.title18Bold.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                    ),
                  ),
                  Text(
                    '${organizer.projectsCount ?? 0} організованих проєктів',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textLightColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildTasksSelection(List<ProjectTaskModel> tasks) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final bool isTaskSelected = _selectedTasks.contains(task);
        final int needed = task.neededPeople ?? 0;
        final int assigned = task.assignedVolunteerIds?.length ?? 0;
        final bool isFull = assigned >= needed;
        final int res = needed - assigned;
        return !isFull && task.status != TaskStatus.confirmed
            ? Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: appThemeColors.primaryWhite,
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
                              task.title ?? 'Назва завдання',
                              style: TextStyleHelper.instance.title16Bold
                                  .copyWith(color: appThemeColors.primaryBlack),
                            ),
                          ),
                          if (needed > 0)
                            Text(
                              isFull
                                  ? 'Заповнено':
                              task.status == TaskStatus.confirmed
                                  ? 'виконано'
                                  : 'Потріб${res > 1 ? 'но' : 'ен'} $res учасник${res > 1 ? 'и' : ''}',
                              style: TextStyleHelper.instance.title14Regular
                                  .copyWith(
                                    color: isFull || task.status == TaskStatus.confirmed
                                        ? appThemeColors.errorRed
                                        : appThemeColors.successGreen,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        task.description ?? 'Опис завдання',
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                      ),
                      if (task.deadline != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            'Дедлайн: ${DateFormat('dd.MM.yyyy').format(task.deadline!)}',
                            style: TextStyleHelper.instance.title13Regular
                                .copyWith(color: appThemeColors.textMediumGrey),
                          ),
                        ),
                      const SizedBox(height: 8),
                      CustomCheckboxWithText(
                        text: 'Хочу долучитися',
                        onChanged: isFull  || task.status == TaskStatus.confirmed
                            ? null // Disable checkbox if task is full
                            : (bool? newValue) {
                                if (newValue != null) {
                                  _toggleTaskSelection(task);
                                }
                              },
                        initialValue: isTaskSelected,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        textStyle: TextStyleHelper.instance.title14Regular
                            .copyWith(
                              color: isFull || task.status == TaskStatus.confirmed
                                  ? appThemeColors.textMediumGrey
                                  : appThemeColors.primaryBlack,
                            ),
                      ),
                      if (isTaskSelected)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: CustomTextField(
                            controller: _messageControllers[task.id!]!,
                            hintText:
                                'Розкажіть, чому ви хочете долучитися до цього завдання...',
                            maxLines: 5,
                            inputType: TextInputType.multiline,
                            labelColor: appThemeColors.primaryBlack,
                            label: 'Супровідне повідомлення',
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : SizedBox.shrink();
      },
    );
  }
}
