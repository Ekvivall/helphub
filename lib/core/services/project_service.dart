import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/project_model.dart';

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
}
