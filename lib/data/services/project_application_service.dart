import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/models/project_application_model.dart';

class ProjectApplicationService {
  final CollectionReference _projectApplicationsCollection = FirebaseFirestore
      .instance
      .collection('projectApplications');

  Future<void> submitProjectApplication(
      ProjectApplicationModel application,) async {
    try {
      await _projectApplicationsCollection
          .doc(application.id)
          .set(application.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<ProjectApplicationModel>> getProjectApplicationsForVolunteer(
      String volunteerUid,) {
    return _projectApplicationsCollection
        .where('volunteerId', isEqualTo: volunteerUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs
              .map(
                (doc) =>
                ProjectApplicationModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
          )
              .toList(),
    );
  }

  Stream<List<ProjectApplicationModel>> getProjectApplicationsForOrganizer(
      String projectId,) {
    return _projectApplicationsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
          snapshot.docs
              .map(
                (doc) =>
                ProjectApplicationModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
          )
              .toList(),
    );
  }

  Future<void> updateProjectApplicationStatus(String applicationId,
      String newStatus) async {
    try {
      await _projectApplicationsCollection.doc(applicationId).update(
          {'status': newStatus});
    } catch(e) {
      rethrow;
    }
  }
}