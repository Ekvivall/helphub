import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:helphub/core/services/event_service.dart';
import 'package:helphub/core/services/project_service.dart';
import 'package:helphub/core/services/fundraising_service.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:helphub/models/report_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/widgets/custom_elevated_button.dart';
import 'package:helphub/widgets/custom_text_field.dart';
import 'package:helphub/widgets/custom_multi_document_upload_field.dart';

import '../../models/organization_model.dart';
import '../../models/participant_feedback_model.dart';
import '../../models/volunteer_model.dart';
import '../../view_models/report/report_view_model.dart';
import '../../widgets/custom_multi_image_upload_field.dart';

class CreateReportScreen extends StatefulWidget {
  final String? reportId; // Для редагування
  final ActivityModel? activity; // Для створення нового звіту

  const CreateReportScreen({super.key, this.reportId, this.activity});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _workDescriptionController =
  TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();
  final TextEditingController _difficultiesController = TextEditingController();
  final TextEditingController _participantsCountController =
  TextEditingController();
  final TextEditingController _fundsRaisedController = TextEditingController();
  final TextEditingController _tasksCompletedController =
  TextEditingController();
  Map<String, TextEditingController> _feedbackControllers = {};

  List<File> _selectedPhotos = [];
  List<File> _selectedDocuments = [];
  List<ParticipantFeedbackModel> _participantsFeedback = [];

  bool _isLoading = true;
  String? _errorMessage;
  String _activityTitle = '';
  ActivityReportType? _activityType;
  List<String>? _participants;

  late ReportViewModel _reportViewModel;

  @override
  void initState() {
    super.initState();
    _reportViewModel = Provider.of<ReportViewModel>(context, listen: false);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.reportId != null) {
        // Завантаження існуючого звіту для редагування
        await _loadExistingReport();
      } else if (widget.activity != null) {
        // Створення нового звіту на основі активності
        await _loadActivityData();
      } else {
        throw Exception('Не вказані дані для створення звіту');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingReport() async {
    await _reportViewModel.loadReport(widget.reportId!);
    final report = _reportViewModel.currentReport;

    if (report != null) {
      _populateFormFields(report);
    } else {
      throw Exception('Звіт не знайдено');
    }
  }

  void _populateFormFields(ReportModel report) {
    setState(() {
      _workDescriptionController.text = report.workDescription;
      _achievementsController.text = report.achievements ?? '';
      _difficultiesController.text = report.difficulties ?? '';
      _participantsCountController.text =
          report.participantsCount?.toString() ?? '';
      _fundsRaisedController.text = report.fundsRaised?.toString() ?? '';
      _tasksCompletedController.text = report.tasksCompleted?.toString() ?? '';
      _activityTitle = report.activityTitle;
      _activityType = report.activityType;
      _participantsFeedback = List.from(report.participantsFeedback);
      _feedbackControllers.clear();
      for (var feedback in _participantsFeedback) {
        _feedbackControllers[feedback.participantId] = TextEditingController(
          text: feedback.feedback,
        );
      }
    });
  }

  Future<void> _loadActivityData() async {
    final activity = widget.activity!;

    switch (activity.type) {
      case ActivityType.eventOrganization:
        final eventService = EventService();
        final event = await eventService.getEventById(activity.entityId);
        if (event != null) {
          setState(() {
            _activityTitle = event.name;
            _activityType = ActivityReportType.event;
            _participants = event.participantIds;
            _participantsCountController.text = event.participantIds.length
                .toString();
          });
          await _loadParticipantsFeedback(event.participantIds);
        }
        break;

      case ActivityType.projectOrganization:
        final projectService = ProjectService();
        final project = await projectService.getProjectById(activity.entityId);
        if (project != null) {
          setState(() {
            _activityTitle = project.title ?? '';
            _activityType = ActivityReportType.project;
            // Отримати учасників проєкту з завдань
            final participantIds = <String>{};
            for (final task in project.tasks ?? []) {
              if (task.assignedVolunteerIds != null) {
                participantIds.addAll(task.assignedVolunteerIds!);
              }
            }
            _participants = participantIds.toList();
            _participantsCountController.text = participantIds.length
                .toString();
            // Підрахувати завершені завдання
            final completedTasks =
                project.tasks
                    ?.where((task) => task.status == TaskStatus.confirmed)
                    .length ??
                    0;
            _tasksCompletedController.text = completedTasks.toString();
          });
          await _loadParticipantsFeedback(_participants!);
        }
        break;

      case ActivityType.fundraiserCreation:
        final fundraisingService = FundraisingService();
        final fundraising = await fundraisingService.getFundraisingById(
          activity.entityId,
        );
        if (fundraising != null) {
          setState(() {
            _activityTitle = fundraising.title ?? '';
            _activityType = ActivityReportType.fundraising;
            _participants = fundraising.donorIds ?? [];
            _fundsRaisedController.text =
                fundraising.currentAmount?.toStringAsFixed(2) ?? '0';
          });
        }
        break;

      default:
        throw Exception('Непідтримуваний тип активності для створення звіту');
    }
  }

  Future<void> _loadParticipantsFeedback(List<String> participantIds) async {
    final feedbackList = <ParticipantFeedbackModel>[];

    for (final participantId in participantIds) {
      try {
        final user = await _reportViewModel.fetchUserProfile(participantId);
        final displayName = user is VolunteerModel
            ? user.fullName ?? user.displayName ?? 'Користувач'
            : user is OrganizationModel
            ? user.organizationName ?? 'Фонд'
            : 'Учасник $participantId';

        feedbackList.add(
          ParticipantFeedbackModel(
            participantId: participantId,
            participantName: displayName,
          ),
        );
      } catch (e) {
        feedbackList.add(
          ParticipantFeedbackModel(
            participantId: participantId,
            participantName: 'Учасник $participantId',
          ),
        );
      }
    }

    setState(() {
      _participantsFeedback = feedbackList;
    });
  }

  void _updateParticipantFeedback(int index, String? feedback) {
    if (index < _participantsFeedback.length) {
      setState(() {
        _participantsFeedback[index] = ParticipantFeedbackModel(
          participantId: _participantsFeedback[index].participantId,
          participantName: _participantsFeedback[index].participantName,
          feedback: feedback,
        );
      });
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final currentUser = _reportViewModel.user;
      if (currentUser == null) {
        throw Exception('Користувач не авторизований');
      }

      final report = ReportModel(
        id: widget.reportId,
        entityId:
        widget.activity?.entityId ??
            _reportViewModel.currentReport!.entityId,
        activityType: _activityType!,
        activityTitle: _activityTitle,
        organizerId: currentUser.uid!,
        organizerName: currentUser is VolunteerModel
            ? currentUser.fullName ?? currentUser.displayName ?? 'Організатор'
            : (currentUser as OrganizationModel).organizationName ??
            'Організація',
        workDescription: _workDescriptionController.text.trim(),
        achievements: _achievementsController.text
            .trim()
            .isEmpty
            ? null
            : _achievementsController.text.trim(),
        difficulties: _difficultiesController.text
            .trim()
            .isEmpty
            ? null
            : _difficultiesController.text.trim(),
        participantsFeedback: _participantsFeedback
            .where((f) => f.feedback != null && f.feedback!.isNotEmpty)
            .toList(),
        organizerFeedback: widget.reportId != null
            ? _reportViewModel.currentReport!.organizerFeedback
            : [],
        createdAt: widget.reportId != null
            ? _reportViewModel.currentReport!.createdAt
            : DateTime.now(),
        updatedAt: widget.reportId != null ? DateTime.now() : null,
        photoUrls: [],
        documentUrls: [],
        participantsCount: int.tryParse(_participantsCountController.text),
        fundsRaised: double.tryParse(_fundsRaisedController.text),
        tasksCompleted: int.tryParse(_tasksCompletedController.text),
      );

      _reportViewModel.setSelectedPhotos(_selectedPhotos);
      _reportViewModel.setSelectedDocuments(_selectedDocuments);

      String? error;
      if (widget.reportId != null) {
        error = await _reportViewModel.updateReport(widget.reportId!, report);
      } else {
        final reportId = await _reportViewModel.createReport(report);
        error = reportId == null ? 'Помилка створення звіту' : null;
      }

      if (error == null && mounted) {
        Constants.showSuccessMessage(
          context,
          widget.reportId != null
              ? 'Звіт успішно оновлено!'
              : 'Звіт успішно створено!',
        );
        Navigator.of(context).pop();
      } else if (error != null && mounted) {
        Constants.showErrorMessage(context, error);
      }
    } catch (e) {
      if (mounted) {
        Constants.showErrorMessage(context, 'Помилка: $e');
      }
    }
  }

  @override
  void dispose() {
    _workDescriptionController.dispose();
    _achievementsController.dispose();
    _difficultiesController.dispose();
    _participantsCountController.dispose();
    _fundsRaisedController.dispose();
    _tasksCompletedController.dispose();
    _feedbackControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.reportId != null;

    return Consumer<ReportViewModel>(
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
              isEditing ? 'Редагувати звіт' : 'Створити звіт',
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
            child: _isLoading || viewModel.isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: appThemeColors.backgroundLightGrey,
              ),
            )
                : _errorMessage != null || viewModel.errorMessage != null
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                      _errorMessage ?? viewModel.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyleHelper.instance.title16Regular
                          .copyWith(
                        color: appThemeColors.backgroundLightGrey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomElevatedButton(
                      onPressed: _loadData,
                      text: 'Спробувати знову',
                      backgroundColor: appThemeColors.blueAccent,
                      textStyle: TextStyleHelper.instance.title16Bold
                          .copyWith(color: appThemeColors.primaryWhite),
                      borderRadius: 10,
                    ),
                  ],
                ),
              ),
            )
                : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок активності
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: appThemeColors.primaryWhite.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: appThemeColors.backgroundLightGrey
                              .withAlpha(77),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Звіт для активності',
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(
                              color: appThemeColors
                                  .backgroundLightGrey
                                  .withAlpha(180),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _activityTitle,
                            style: TextStyleHelper.instance.title18Bold
                                .copyWith(
                              color:
                              appThemeColors.backgroundLightGrey,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Статистика залежно від типу активності
                          _buildStatisticsSection(),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: appThemeColors.blueAccent.withAlpha(
                                77,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getActivityTypeLabel(),
                              style: TextStyleHelper
                                  .instance
                                  .title13Regular
                                  .copyWith(
                                color: appThemeColors
                                    .backgroundLightGrey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Опис виконаної роботи
                    CustomTextField(
                      controller: _workDescriptionController,
                      label: 'Опис виконаної роботи',
                      hintText:
                      'Детально опишіть що було зроблено, як проходила активність...',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.multiline,
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value
                            .trim()
                            .isEmpty) {
                          return 'Будь ласка, опишіть виконану роботу';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Досягнуті результати
                    CustomTextField(
                      controller: _achievementsController,
                      label: 'Досягнуті результати',
                      hintText:
                      'Опишіть основні досягнення та позитивні результати...',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.multiline,
                      maxLines: 4,
                      isRequired: false,
                    ),
                    const SizedBox(height: 20),

                    // Труднощі та рекомендації
                    CustomTextField(
                      controller: _difficultiesController,
                      label: 'Труднощі та рекомендації',
                      hintText:
                      'Опишіть труднощі, з якими зіткнулись, та рекомендації на майбутнє...',
                      labelColor: appThemeColors.backgroundLightGrey,
                      inputType: TextInputType.multiline,
                      maxLines: 4,
                      isRequired: false,
                    ),
                    const SizedBox(height: 20),

                    // Фото
                    CustomMultiImageUploadField(
                      labelText: 'Фото звіту',
                      onChanged: (files) {
                        setState(() {
                          _selectedPhotos = files;
                        });
                      },
                      initialImageUrls: widget.reportId != null ? viewModel
                          .currentReport?.photoUrls : null,
                    ),
                    const SizedBox(height: 20),

                    // Документи
                    CustomMultiDocumentUploadField(
                      labelText: 'Додаткові документи (необов\'язково)',
                      onChanged: (files) {
                        setState(() {
                          _selectedDocuments = files;
                        });
                      },
                      initialDocumentUrls:widget.reportId != null ?
                      viewModel.currentReport?.documentUrls : null,
                    ),
                    const SizedBox(height: 20),

                    // Відгуки про учасників
                    if (_participantsFeedback.isNotEmpty) ...[
                      _buildParticipantsFeedbackSection(),
                      const SizedBox(height: 20),
                    ],

                    // Кнопки
                    Row(
                      children: [
                        Expanded(
                          child: CustomElevatedButton(
                            onPressed: viewModel.isUploadingFiles
                                ? null
                                : () => Navigator.of(context).pop(),
                            text: 'Скасувати',
                            backgroundColor:
                            appThemeColors.textMediumGrey,
                            textStyle: TextStyleHelper
                                .instance
                                .title16Bold
                                .copyWith(
                              color: appThemeColors.primaryWhite,
                            ),
                            borderRadius: 10,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomElevatedButton(
                            onPressed: viewModel.isUploadingFiles
                                ? null
                                : _submitReport,
                            isLoading: viewModel.isUploadingFiles,
                            text: isEditing
                                ? 'Зберегти зміни'
                                : 'Створити звіт',
                            backgroundColor: appThemeColors.successGreen,
                            textStyle: TextStyleHelper
                                .instance
                                .title16Bold
                                .copyWith(
                              color: appThemeColors.primaryWhite,
                            ),
                            borderRadius: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getActivityTypeLabel() {
    switch (_activityType) {
      case ActivityReportType.event:
        return 'Подія';
      case ActivityReportType.project:
        return 'Проєкт';
      case ActivityReportType.fundraising:
        return 'Збір коштів';
      default:
        return 'Невідомо';
    }
  }

  Widget _buildStatisticsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_activityType == ActivityReportType.event ||
            _activityType == ActivityReportType.project) ...[
          Text(
            'Кількість учасників: ${_participantsCountController.text.isNotEmpty
                ? _participantsCountController.text
                : "0"}',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ],

        if (_activityType == ActivityReportType.project) ...[
          const SizedBox(height: 8),
          Text(
            'Виконано завдань: ${_tasksCompletedController.text.isNotEmpty
                ? _tasksCompletedController.text
                : "0"}',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ],

        if (_activityType == ActivityReportType.fundraising) ...[
          Text(
            'Зібрано коштів (грн): ${_fundsRaisedController.text.isNotEmpty
                ? _fundsRaisedController.text
                : "0.00"}',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildParticipantsFeedbackSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: appThemeColors.backgroundLightGrey.withAlpha(77),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Відгуки про учасників (необов\'язково)',
            style: TextStyleHelper.instance.title16Bold.copyWith(
              color: appThemeColors.backgroundLightGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Залиште відгук про роботу учасників під час активності',
            style: TextStyleHelper.instance.title14Regular.copyWith(
              color: appThemeColors.backgroundLightGrey.withAlpha(180),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_participantsFeedback.length, (index) {
            final participant = _participantsFeedback[index];
            if (!_feedbackControllers.containsKey(participant.participantId)) {
              _feedbackControllers[participant.participantId] =
                  TextEditingController(text: participant.feedback);
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: appThemeColors.blueMixedColor.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: appThemeColors.backgroundLightGrey.withAlpha(77),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.participantName,
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Текстовий відгук
                  TextField(
                    controller: _feedbackControllers[participant.participantId],
                    onChanged: (value) =>
                        _updateParticipantFeedback(
                          index,
                          value.isEmpty ? null : value,
                        ),
                    decoration: InputDecoration(
                      hintText: 'Залишити відгук про учасника...',
                      hintStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(
                        color: appThemeColors.backgroundLightGrey.withAlpha(
                          128,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.backgroundLightGrey.withAlpha(
                            77,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.backgroundLightGrey.withAlpha(
                            77,
                          ),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: appThemeColors.backgroundLightGrey,
                        ),
                      ),
                      filled: true,
                      fillColor: appThemeColors.primaryWhite.withAlpha(25),
                    ),
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.backgroundLightGrey,
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
