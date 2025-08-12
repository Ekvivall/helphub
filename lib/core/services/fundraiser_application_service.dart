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

  // Отримання заявок з конкретним статусом для фонду
  Stream<List<FundraiserApplicationModel>>
  getApplicationsByStatusForOrganization(
    String organizationId,
    FundraisingStatus status,
  ) {
    return _fundraiserApplicationsCollection
        .where('organizationId', isEqualTo: organizationId)
        .where('status', isEqualTo: status.name)
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

  // Отримання схвалених заявок для фонду (одноразово)
  Future<List<FundraiserApplicationModel>>
  getApprovedApplicationsForOrganization(String organizationId) async {
    try {
      final querySnapshot = await _fundraiserApplicationsCollection
          .where('organizationId', isEqualTo: organizationId)
          .where(
            'status',
            whereIn: [
              FundraisingStatus.approved.name, //Схвалені, але ще не в процесі
            ],
          )
          .orderBy('timestamp', descending: true)
          .get();
      return querySnapshot.docs
          .map(
            (doc) => FundraiserApplicationModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveFundraisingApplication(String applicationId) async {
    try {
      await _fundraiserApplicationsCollection.doc(applicationId).update({
        'status': FundraisingStatus.approved.name,
        'rejectionReason': null,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectFundraisingApplication(
    String applicationId,
    String reason,
  ) async {
    try {
      await _fundraiserApplicationsCollection.doc(applicationId).update({
        'status': FundraisingStatus.rejected.name,
        'rejectionReason': reason,
      });
    } catch (e) {
      rethrow;
    }
  }

  // Оновлення статусу заявки
  Future<void> updateApplicationStatus(
    String applicationId,
    FundraisingStatus status, {
    String? rejectionReason,
  }) async {
    try {
      final Map<String, dynamic> updatedData = {'status': status.name};

      if (status == FundraisingStatus.rejected && rejectionReason != null) {
        updatedData['rejectionReason'] = rejectionReason;
      } else {
        updatedData['rejectionReason'] = null;
      }

      await _fundraiserApplicationsCollection
          .doc(applicationId)
          .update(updatedData);
    } catch (e) {
      rethrow;
    }
  }

  // Масове оновлення статусу заявок (для завершення збору)
  Future<void> updateMultipleApplicationsStatus(
    List<String> applicationIds,
    FundraisingStatus status,
  ) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      for (String applicationId in applicationIds) {
        final docRef = _fundraiserApplicationsCollection.doc(applicationId);
        batch.update(docRef, {'status': status.name, 'rejectionReason': null});
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  // Отриманні заявки за ID
  Future<FundraiserApplicationModel?> getApplicationById(
    String applicationId,
  ) async {
    try {
      final docSnapshot = await _fundraiserApplicationsCollection
          .doc(applicationId)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return FundraiserApplicationModel.fromMap(
          docSnapshot.id,
          docSnapshot.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
