import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:helphub/core/services/project_application_service.dart';
import 'package:helphub/core/services/project_service.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/models/project_application_model.dart';
import 'package:helphub/models/project_model.dart';
import 'package:helphub/models/project_task_model.dart';

import '../../core/services/activity_service.dart';
import '../../core/services/chat_service.dart';
import '../../models/activity_model.dart';
import '../../models/organization_model.dart';
import '../../models/volunteer_model.dart';

class ChatTaskViewModel extends ChangeNotifier {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final ProjectService _projectService = ProjectService();
  final ProjectApplicationService _applicationService =
      ProjectApplicationService();
  final ActivityService _activityService = ActivityService();
  final ChatService _chatService = ChatService();

  ProjectModel? _project;
  List<ProjectTaskModel> _allTasks = [];
  List<ProjectApplicationModel> _allApplications = [];
  final Map<String, BaseProfileModel> _volunteersData = {};

  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription? _projectSubscription;
  StreamSubscription? _applicationsSubscription;

  ProjectModel? get project => _project;

  List<ProjectTaskModel> get allTasks => _allTasks;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  String get currentUserId => _currentUserId;

  List<ProjectTaskModel> get myTasks {
    return _allTasks
        .where(
          (task) =>
              task.assignedVolunteerIds?.contains(_currentUserId) ?? false,
        )
        .toList();
  }

  List<ProjectTaskModel> get completedTasks {
    return _allTasks
        .where((task) => task.status == TaskStatus.confirmed)
        .toList();
  }

  List<ProjectApplicationModel> getApplicationsForTask(String taskId) {
    return _allApplications
        .where((app) => app.taskId == taskId && app.status == 'pending')
        .toList();
  }

  BaseProfileModel? getVolunteerProfile(String uid) => _volunteersData[uid];

  void listenToProjectTasks(String projectId) {
    _isLoading = true;
    _projectSubscription?.cancel();
    _applicationsSubscription?.cancel();
    _projectSubscription = _projectService
        .getProjectStream(projectId)
        .listen(
          (project) async {
            _project = project;
            final tasks = project.tasks ?? [];
            _allTasks = _sortTasksByStatus(tasks);
            await _fetchApplicationsAndVolunteers();
            _isLoading = false;
            _errorMessage = null;
            notifyListeners();
          },
          onError: (error) {
            _errorMessage = 'Помилка завантаження завдань: $error';
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  List<ProjectTaskModel> _sortTasksByStatus(List<ProjectTaskModel> tasks) {
    final sortedTasks = List<ProjectTaskModel>.from(tasks);

    sortedTasks.sort((a, b) {
      final statusPriority = _getStatusPriority(
        a.status,
      ).compareTo(_getStatusPriority(b.status));
      if (statusPriority != 0) return statusPriority;

      if (a.deadline != null && b.deadline != null) {
        return a.deadline!.compareTo(b.deadline!);
      } else if (a.deadline != null) {
        return -1;
      } else if (b.deadline != null) {
        return 1;
      }

      return 0;
    });

    return sortedTasks;
  }

  int _getStatusPriority(TaskStatus? status) {
    switch (status) {
      case TaskStatus.completed:
        return 1; // Найвищий пріоритет - відкриті завдання
      case TaskStatus.pending:
        return 2; // Завдання в процесі
      case TaskStatus.inProgress:
        return 3; // Завдання на підтвердженні
      case TaskStatus.confirmed:
        return 4; // Найнижчий пріоритет - підтверджені завдання
      default:
        return 0; // Невідомий статус - найвищий пріоритет
    }
  }

  Future<void> _fetchApplicationsAndVolunteers() async {
    final appStream = _applicationService.getProjectApplicationsForOrganizer(
      _project!.id!,
    );
    _applicationsSubscription?.cancel();
    _applicationsSubscription = appStream.listen(
      (applications) async {
        _allApplications = applications;
        final volunteerIds = applications.map((app) => app.volunteerId).toSet();
        await _loadVolunteerProfiles(volunteerIds);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Помилка завантаження заявок: $error';
        notifyListeners();
      },
    );
  }

  Future<void> _loadVolunteerProfiles(Set<String> volunteerIds) async {
    for (var id in volunteerIds) {
      if (!_volunteersData.containsKey(id)) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(id)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data();
          final roleString = data?['role'] as String?;
          if (roleString == UserRole.volunteer.name) {
            _volunteersData[id] = VolunteerModel.fromMap(doc.data()!);
          } else {
            _volunteersData[id] = OrganizationModel.fromMap(doc.data()!);
          }
        }
      }
    }
  }

  Future<void> handleApplication({
    required String projectId,
    required ProjectTaskModel task,
    required ProjectApplicationModel application,
    required bool accept,
  }) async {
    if (accept) {
      // Оновлення статусу заявки
      await _applicationService.updateProjectApplicationStatus(
        application.id,
        'approved',
      );
      // Додавання волонтера до списку
      final List<String> updateAssignedIds = [
        ...?task.assignedVolunteerIds,
        application.volunteerId,
      ];
      // Оновлення завдання в проєкті
      final updatedTask = task.copyWith(
        assignedVolunteerIds: updateAssignedIds,
        status: TaskStatus.inProgress,
      );
      await _projectService.updateTaskInProject(_project!.id!, updatedTask);
      final activity = ActivityModel(
        type: ActivityType.projectParticipation,
        entityId: projectId,
        title: 'Завдання "${task.title}" в проєкті "${_project?.title}"',
        description: task.description,
        timestamp: DateTime.now(),
      );
      await _activityService.logActivity(application.volunteerId, activity);
      // Логіка відхилення інших заявок, тільки якщо набрана потрібна кількість волонтерів
      if (updateAssignedIds.length >= task.neededPeople!) {
        final pendingApplicationsForTask = _allApplications
            .where(
              (app) =>
                  app.taskId == task.id &&
                  app.status == 'pending' &&
                  app.id != application.id,
            )
            .toList();

        for (var app in pendingApplicationsForTask) {
          await _applicationService.updateProjectApplicationStatus(
            app.id,
            'rejected',
          );
        }
      }
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'project')
          .where('entityId', isEqualTo: projectId)
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        final chatId = chatQuery.docs.first.id;
        await _chatService.addParticipant(chatId, application.volunteerId);
        print(
          'Added volunteer ${application.volunteerId} to project chat $chatId',
        );
      }
    } else {
      await _applicationService.updateProjectApplicationStatus(
        application.id,
        'rejected',
      );
    }
  }

  Future<void> confirmTaskCompletion({
    required String projectId,
    required ProjectTaskModel task,
  }) async {
    final updatedTask = task.copyWith(status: TaskStatus.confirmed);
    await _projectService.updateTaskInProject(projectId, updatedTask);
  }

  Future<void> rejectTaskCompletion({
    required String projectId,
    required ProjectTaskModel task,
  }) async {
    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      completedByVolunteerId: null,
    );
    await _projectService.updateTaskInProject(projectId, updatedTask);
  }

  Future<void> markTaskAsCompleted({
    required String projectId,
    required ProjectTaskModel task,
    required String volunteerId,
  }) async {
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedByVolunteerId: volunteerId,
      completionDate: DateTime.now(),
    );
    await _projectService.updateTaskInProject(projectId, updatedTask);
  }

  Future<void> assignSelfToTask({required ProjectTaskModel task}) async {
    try {
      final List<String> updatedAssignedIds = [
        ...?task.assignedVolunteerIds,
        _currentUserId,
      ];

      final updatedTask = task.copyWith(
        assignedVolunteerIds: updatedAssignedIds,
        status: TaskStatus.inProgress,
      );

      await _projectService.updateTaskInProject(_project!.id!, updatedTask);
      final activity = ActivityModel(
        type: ActivityType.projectParticipation,
        entityId: project!.id!,
        title: 'Завдання "${task.title}" в проєкті "${_project?.title}"',
        description: task.description,
        timestamp: DateTime.now(),
      );
      await _activityService.logActivity(currentUserId, activity);
    } catch (e) {
      _errorMessage = 'Помилка призначення на завдання: $e';
      notifyListeners();
      rethrow;
    }
  }
}
