import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/models/report_model.dart';
import 'package:helphub/core/services/report_service.dart';

import '../../core/services/user_service.dart';
import '../../models/organization_model.dart';
import '../../models/organizer_feedback_model.dart';
import '../../models/participant_feedback_model.dart';
import '../../models/volunteer_model.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportService _reportService = ReportService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isUploadingFiles = false;
  String? _errorMessage;

  ReportModel? _currentReport;

  List<File> _selectedPhotos = [];
  List<File> _selectedDocuments = [];

  bool get isLoading => _isLoading;

  bool get isUploadingFiles => _isUploadingFiles;

  String? get errorMessage => _errorMessage;

  ReportModel? get currentReport => _currentReport;

  List<File> get selectedPhotos => _selectedPhotos;

  List<File> get selectedDocuments => _selectedDocuments;

  String? _currentUserId;

  String? get currentUserId => _currentUserId;
  BaseProfileModel? _user;
  BaseProfileModel? get user => _user;

  ReportViewModel() {
    _auth.authStateChanges().listen((user) async {
      _currentUserId = user?.uid;
      _user = await _userService.fetchUserProfile(_currentUserId);
      notifyListeners();
    });
  }


  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void setSelectedPhotos(List<File> photos) {
    _selectedPhotos = photos;
    notifyListeners();
  }

  void setSelectedDocuments(List<File> documents) {
    _selectedDocuments = documents;
    notifyListeners();
  }

  Future<String?> createReport(ReportModel report) async {
    _isUploadingFiles = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final reportId = await _reportService.createReport(
        report,
        _selectedPhotos,
        _selectedDocuments,
      );

      if (reportId != null) {
        _selectedPhotos.clear();
        _selectedDocuments.clear();
        notifyListeners();
      }

      return reportId;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isUploadingFiles = false;
      notifyListeners();
    }
  }

  Future<String?> updateReport(String reportId, ReportModel report) async {
    _isUploadingFiles = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _reportService.updateReport(
        reportId,
        report,
        _selectedPhotos,
        _selectedDocuments,
      );

      _selectedPhotos.clear();
      _selectedDocuments.clear();

      await loadReport(reportId);

      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return _errorMessage;
    } finally {
      _isUploadingFiles = false;
      notifyListeners();
    }
  }

  Future<void> loadReport(String reportId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentReport = await _reportService.getReportById(reportId);
      if (_currentReport == null) {
        _errorMessage = 'Звіт не знайдено';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> addOrganizerFeedback(
    String reportId,
    String? feedback,
    int? rating,
    bool isAnonymous,
  ) async {
    _errorMessage = null;

    try {
      if (_user == null) {
        throw Exception('Користувач не авторизований');
      }

      final feedbackModel = OrganizerFeedbackModel(
        participantId: _user!.uid!,
        participantName: isAnonymous
            ? 'Анонімний учасник'
            : _user is VolunteerModel
            ? (_user as VolunteerModel).displayName ?? 'Користувач'
            : (_user as OrganizationModel).organizationName ?? 'Фонд',
        feedback: feedback,
        rating: rating,
        isAnonymous: isAnonymous,
      );

      await _reportService.addOrganizerFeedback(reportId, feedbackModel);

      // Перезавантажити звіт для показу нового відгуку
      await loadReport(reportId);

      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<String?> updateParticipantsFeedback(
    String reportId,
    List<ParticipantFeedbackModel> feedback,
  ) async {
    _errorMessage = null;

    try {
      await _reportService.updateParticipantsFeedback(reportId, feedback);

      // Оновити поточний звіт
      if (_currentReport?.id == reportId) {
        _currentReport = _currentReport!.copyWith(
          participantsFeedback: feedback,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }

      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<String?> deleteReport(String reportId) async {
    _errorMessage = null;

    try {
      await _reportService.deleteReport(reportId);

      // Очистити поточний звіт, якщо він був видалений
      if (_currentReport?.id == reportId) {
        _currentReport = null;
      }

      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<String?> removePhotoFromReport(
    String reportId,
    String photoUrl,
  ) async {
    _errorMessage = null;

    try {
      await _reportService.removePhotoFromReport(reportId, photoUrl);

      // Оновити звіт у списках
      _updateReportInLists(reportId, (report) {
        final updatedPhotos = report.photoUrls
            .where((url) => url != photoUrl)
            .toList();
        return report.copyWith(
          photoUrls: updatedPhotos,
          updatedAt: DateTime.now(),
        );
      });

      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<String?> removeDocumentFromReport(
    String reportId,
    String documentUrl,
  ) async {
    _errorMessage = null;

    try {
      await _reportService.removeDocumentFromReport(reportId, documentUrl);

      // Оновити звіт у списках
      _updateReportInLists(reportId, (report) {
        final updatedDocs = report.documentUrls
            .where((url) => url != documentUrl)
            .toList();
        return report.copyWith(
          documentUrls: updatedDocs,
          updatedAt: DateTime.now(),
        );
      });

      return null;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<bool> hasUserLeftFeedback(String reportId, [String? userId]) async {
    try {
      final user = userId ?? currentUserId;
      if (user == null) return false;

      return await _reportService.hasUserLeftFeedback(reportId, user);
    } catch (e) {
      return false;
    }
  }

  Future<ParticipantFeedbackModel?> getParticipantFeedback(
    String reportId,
    String participantId,
  ) async {
    try {
      return await _reportService.getParticipantFeedback(
        reportId,
        participantId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<int> getOrganizerFeedbackCount(String reportId) async {
    try {
      return await _reportService.getOrganizerFeedbackCount(reportId);
    } catch (e) {
      return 0;
    }
  }

  void _updateReportInLists(
    String reportId,
    ReportModel Function(ReportModel) updater,
  ) {
    // Оновити поточний звіт
    if (_currentReport?.id == reportId) {
      _currentReport = updater(_currentReport!);
    }

    notifyListeners();
  }

  void clearAll() {
    _isLoading = false;
    _isUploadingFiles = false;
    _errorMessage = null;
    _currentReport = null;
    _selectedPhotos.clear();
    _selectedDocuments.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    clearAll();
    super.dispose();
  }
}
