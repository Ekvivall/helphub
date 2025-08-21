import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/project_model.dart';
import 'package:helphub/models/project_task_model.dart';

class ProjectService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createProject(ProjectModel project) async {
    try {
      final projectRef = _firestore.collection('projects').doc(project.id);
      final newProjectId = project.id ?? projectRef.id;
      final projectToSave = project.copyWith(
        id: newProjectId,
        timestamp: DateTime.now(),
      );
      await projectRef.set(projectToSave.toMap());
      return newProjectId;
    } catch (e) {
      rethrow;
    }
  }

  Future<ProjectModel?> getProjectById(String id) async {
    try {
      final docSnapshot = await _firestore.collection('projects').doc(id).get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return ProjectModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProject(ProjectModel project) async {
    if (project.id == null || project.id!.isEmpty) {
      throw ArgumentError('ProjectModel must have a non-null ID for update.');
    }
    try {
      await _firestore
          .collection('projects')
          .doc(project.id)
          .update(project.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await _firestore.collection('projects').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ProjectModel>> fetchProjectsStream() {
    return _firestore.collection('projects').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
    });
  }

  Stream<ProjectModel> getProjectStream(String projectId) {
    return _firestore.collection('projects').doc(projectId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return ProjectModel.fromMap(snapshot.data()!);
      } else {
        throw Exception('Project not found or data is empty.');
      }
    });
  }

  Future<List<ProjectModel>> fetchProjectsOnce() async {
    try {
      final querySnapshot = await _firestore.collection('projects').get();
      return querySnapshot.docs
          .map((doc) => ProjectModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateTaskInProject(
    String projectId,
    ProjectTaskModel updatedTask,
  ) async {
    try {
      final projectRef = _firestore.collection('projects').doc(projectId);
      final projectSnapshot = await projectRef.get();
      if (!projectSnapshot.exists) {
        throw Exception('Проєкт з ID $projectId не знайдено.');
      }
      final projectData = projectSnapshot.data();
      if (projectData == null || projectData['tasks'] == null) {
        throw Exception('Завдання в проєкті не знайдено.');
      }
      List<dynamic> tasksList = projectData['tasks'];
      final List<ProjectTaskModel> tasks = tasksList
          .map(
            (taskMap) =>
                ProjectTaskModel.fromMap(taskMap, taskMap['id'] as String),
          )
          .toList();
      // Індекс завдання для оновлення
      final taskIndex = tasks.indexWhere((task) => task.id == updatedTask.id);
      if (taskIndex != -1) {
        // Заміна старого значення на оновлене
        tasks[taskIndex] = updatedTask;
        // Оновлення документу проєкту, записуючи оновлений список завдань
        await projectRef.update({
          'tasks': tasks.map((t) => t.toMap()).toList(),
        });
      } else {
        throw Exception(
          'Завдання з ID ${updatedTask.id} не знайдено у проєкті.',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, ProjectModel>> getProjectByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final Map<String, ProjectModel> eventsMap = {};
    final querySnapshot = await _firestore
        .collection('projects')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    for (var doc in querySnapshot.docs) {
      eventsMap[doc.id] = ProjectModel.fromMap(doc.data());
    }
    return eventsMap;
  }
}
