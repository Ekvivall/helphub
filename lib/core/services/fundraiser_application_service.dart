import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/fundraiser_application_model.dart';

class FundraiserApplicationService {
  final CollectionReference _fundraiserApplicationsCollection =
      FirebaseFirestore.instance.collection('fundraiserApplications');

  Future<void> submitFundraiserApplication(
    FundraiserApplicationModel application,
  ) async {
    try {
      await _fundraiserApplicationsCollection
          .doc(application.id)
          .set(application.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<FundraiserApplicationModel>>
  getFundraiserApplicationsForVolunteer(String volunteerUid) {
    return _fundraiserApplicationsCollection
        .where('volunteerId', isEqualTo: volunteerUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FundraiserApplicationModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Stream<List<FundraiserApplicationModel>>
  getFundraiserApplicationsForOrganizer(String organizerUid) {
    return _fundraiserApplicationsCollection
        .where('organizationId', isEqualTo: organizerUid)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => FundraiserApplicationModel.fromMap(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList(),
        );
  }

  Future<void> updateFundraiserApplicationStatus(
    String applicationId,
    String newStatus,
  ) async {
    try {
      await _fundraiserApplicationsCollection.doc(applicationId).update({
        'status': newStatus,
      });
    } catch (e) {
      rethrow;
    }
  }
}
