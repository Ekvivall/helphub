import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:helphub/data/models/report_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

import '../../data/models/organizer_feedback_model.dart';
import '../../data/models/participant_feedback_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final String _reportsCollection = 'reports';

  Future<String?> createReport(
    ReportModel report,
    List<File> photos,
    List<File> documents,
  ) async {
    try {
      final String reportId = const Uuid().v4();

      List<String> photoUrls = [];
      if (photos.isNotEmpty) {
        photoUrls = await _uploadFiles(photos, 'reports/$reportId/photos');
      }

      List<String> documentUrls = [];
      if (documents.isNotEmpty) {
        documentUrls = await _uploadFiles(
          documents,
          'reports/$reportId/documents',
        );
      }

      final reportWithFiles = report.copyWith(
        id: reportId,
        photoUrls: photoUrls,
        documentUrls: documentUrls,
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .set(reportWithFiles.toMap());

      await _updateEntityReportId(
        report.entityId,
        report.activityType,
        reportId,
      );

      return reportId;
    } catch (e) {
      throw Exception('Помилка створення звіту: $e');
    }
  }

  Future<String?> updateReport(
    String reportId,
    ReportModel report,
    List<File> newPhotos,
    List<File> newDocuments,
  ) async {
    try {
      final currentReport = await getReportById(reportId);
      if (currentReport == null) {
        throw Exception('Звіт не знайдено');
      }

      List<String> newPhotoUrls = [];
      if (newPhotos.isNotEmpty) {
        newPhotoUrls = await _uploadFiles(
          newPhotos,
          'reports/$reportId/photos',
        );
      }

      List<String> newDocumentUrls = [];
      if (newDocuments.isNotEmpty) {
        newDocumentUrls = await _uploadFiles(
          newDocuments,
          'reports/$reportId/documents',
        );
      }

      final allPhotoUrls = [...currentReport.photoUrls, ...newPhotoUrls];
      final allDocumentUrls = [
        ...currentReport.documentUrls,
        ...newDocumentUrls,
      ];

      final updatedReport = report.copyWith(
        id: reportId,
        photoUrls: allPhotoUrls,
        documentUrls: allDocumentUrls,
        createdAt: currentReport.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .update(updatedReport.toMap());

      return null;
    } catch (e) {
      throw Exception('Помилка оновлення звіту: $e');
    }
  }

  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _firestore
          .collection(_reportsCollection)
          .doc(reportId)
          .get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return ReportModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Помилка завантаження звіту: $e');
    }
  }

  Future<void> addOrganizerFeedback(
    String reportId,
    OrganizerFeedbackModel feedback,
  ) async {
    try {
      final reportRef = _firestore.collection(_reportsCollection).doc(reportId);

      await _firestore.runTransaction((transaction) async {
        final reportDoc = await transaction.get(reportRef);

        if (!reportDoc.exists) {
          throw Exception('Звіт не знайдено');
        }

        final currentReport = ReportModel.fromMap(
          reportDoc.data()!,
          reportDoc.id,
        );

        // Перевірити, чи користувач уже залишав відгук
        final existingFeedbackIndex = currentReport.organizerFeedback
            .indexWhere((f) => f.participantId == feedback.participantId);

        List<OrganizerFeedbackModel> updatedFeedback = [
          ...currentReport.organizerFeedback,
        ];

        if (existingFeedbackIndex != -1) {
          // Оновити існуючий відгук
          updatedFeedback[existingFeedbackIndex] = feedback;
        } else {
          // Додати новий відгук
          updatedFeedback.add(feedback);
        }

        transaction.update(reportRef, {
          'organizerFeedback': updatedFeedback.map((f) => f.toMap()).toList(),
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      });
    } catch (e) {
      throw Exception('Помилка додавання відгуку: $e');
    }
  }

  Future<void> updateParticipantsFeedback(
    String reportId,
    List<ParticipantFeedbackModel> feedback,
  ) async {
    try {
      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'participantsFeedback': feedback.map((f) => f.toMap()).toList(),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Помилка оновлення відгуків про учасників: $e');
    }
  }

  Future<void> deleteReport(String reportId) async {
    try {
      final report = await getReportById(reportId);
      if (report != null) {
        for (final photoUrl in report.photoUrls) {
          await _deleteFileByUrl(photoUrl);
        }

        for (final documentUrl in report.documentUrls) {
          await _deleteFileByUrl(documentUrl);
        }

        await _firestore.collection(_reportsCollection).doc(reportId).delete();

        await _updateEntityReportId(report.entityId, report.activityType, null);
      }
    } catch (e) {
      throw Exception('Помилка видалення звіту: $e');
    }
  }

  Future<ParticipantFeedbackModel?> getParticipantFeedback(
    String reportId,
    String participantId,
  ) async {
    try {
      final report = await getReportById(reportId);
      if (report == null) return null;

      return report.participantsFeedback
          .cast<ParticipantFeedbackModel?>()
          .firstWhere(
            (feedback) => feedback?.participantId == participantId,
            orElse: () => null,
          );
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasUserLeftFeedback(String reportId, String userId) async {
    try {
      final report = await getReportById(reportId);
      if (report == null) return false;

      return report.organizerFeedback.any(
        (feedback) => feedback.participantId == userId,
      );
    } catch (e) {
      return false;
    }
  }

  Future<int> getOrganizerFeedbackCount(String reportId) async {
    try {
      final report = await getReportById(reportId);
      return report?.organizerFeedback.length ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<List<String>> _uploadFiles(List<File> files, String basePath) async {
    final List<String> urls = [];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final fileName = '${const Uuid().v4()}${p.extension(file.path)}';
      final ref = _storage.ref().child('$basePath/$fileName');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  Future<void> _deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Помилка оновлення reportId в сутності: $e');
    }
  }

  Future<void> removePhotoFromReport(String reportId, String photoUrl) async {
    try {
      final report = await getReportById(reportId);
      if (report == null) {
        throw Exception('Звіт не знайдено');
      }

      // Видалити фото з Firebase Storage
      await _deleteFileByUrl(photoUrl);

      // Оновити список фото в звіті
      final updatedPhotos = report.photoUrls
          .where((url) => url != photoUrl)
          .toList();

      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'photoUrls': updatedPhotos,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Помилка видалення фото: $e');
    }
  }

  Future<void> removeDocumentFromReport(
    String reportId,
    String documentUrl,
  ) async {
    try {
      final report = await getReportById(reportId);
      if (report == null) {
        throw Exception('Звіт не знайдено');
      }

      // Видалити документ з Firebase Storage
      await _deleteFileByUrl(documentUrl);

      // Оновити список документів в звіті
      final updatedDocuments = report.documentUrls
          .where((url) => url != documentUrl)
          .toList();

      await _firestore.collection(_reportsCollection).doc(reportId).update({
        'documentUrls': updatedDocuments,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Помилка видалення документу: $e');
    }
  }

  /// Оновити reportId в відповідній сутності
  Future<void> _updateEntityReportId(
    String entityId,
    ActivityReportType activityType,
    String? reportId,
  ) async {
    try {
      String collection;
      switch (activityType) {
        case ActivityReportType.event:
          collection = 'events';
          break;
        case ActivityReportType.project:
          collection = 'projects';
          break;
        case ActivityReportType.fundraising:
          collection = 'fundraisings';
          break;
      }

      await _firestore.collection(collection).doc(entityId).update({
        'reportId': reportId,
      });
    } catch (e) {rethrow;}
  }
}
