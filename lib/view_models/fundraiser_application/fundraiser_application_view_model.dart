import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:helphub/core/services/category_service.dart';
import 'package:helphub/core/services/fundraiser_application_service.dart';
import 'package:helphub/models/volunteer_model.dart';
import 'package:path/path.dart' as p;

import '../../models/base_profile_model.dart';
import '../../models/category_chip_model.dart';
import '../../models/fundraiser_application_model.dart';
import '../../models/organization_model.dart';

class FundraiserApplicationViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FundraiserApplicationService _applicationService =
      FundraiserApplicationService();
  final CategoryService _categoryService = CategoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<List<FundraiserApplicationModel>>?
  _applicationsSubscription;
  StreamSubscription<List<FundraiserApplicationModel>>?
  _approvedApplicationsSubscription;

  List<FundraiserApplicationModel> _userApplications = [];
  List<FundraiserApplicationModel> _organizationApplications = [];
  List<FundraiserApplicationModel> _approvedApplications = [];
  List<OrganizationModel> _availableOrganizations = [];
  List<CategoryChipModel> _availableCategories = [];

  bool _isLoading = false;
  bool _isUploadingFiles = false;
  String? _errorMessage;

  File? _pickedImageFile;
  List<File> _pickedDocuments = [];

  String? _currentAuthUserId;
  BaseProfileModel? _user;

  // Getters
  List<FundraiserApplicationModel> get userApplications => _userApplications;

  List<FundraiserApplicationModel> get organizationApplications =>
      _organizationApplications;

  List<FundraiserApplicationModel> get approvedApplications =>
      _approvedApplications;

  List<OrganizationModel> get availableOrganizations => _availableOrganizations;

  List<CategoryChipModel> get availableCategories => _availableCategories;

  bool get isLoading => _isLoading;

  bool get isUploadingFiles => _isUploadingFiles;

  String? get errorMessage => _errorMessage;

  File? get pickedImageFile => _pickedImageFile;

  List<File> get pickedDocuments => _pickedDocuments;

  String? get currentAuthUserId => _currentAuthUserId;

  BaseProfileModel? get user => _user;

  FundraiserApplicationViewModel() {
    _auth.authStateChanges().listen((user) async {
      _currentAuthUserId = user?.uid;
      _user = await fetchUserProfile(_currentAuthUserId);
      _loadInitialData();
    });
  }

  Future<BaseProfileModel?> fetchUserProfile(String? userId) async {
    try {
      if (userId == null) return null;
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        final roleString = data?['role'] as String?;
        if (roleString == UserRole.volunteer.name) {
          return VolunteerModel.fromMap(doc.data()!);
        } else {
          return OrganizationModel.fromMap(doc.data()!);
        }
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> _loadInitialData() async {
    await _loadAvailableCategories();
    await _loadAvailableOrganizations();
    _listenToUserApplications();
  }

  Future<void> _loadAvailableCategories() async {
    try {
      _availableCategories = await _categoryService.fetchCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading available categories: $e');
    }
  }

  Future<void> _loadAvailableOrganizations() async {
    if (_user == null || user is! VolunteerModel) return;
    try {
      _isLoading = true;
      notifyListeners();

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: UserRole.organization.name)
          .get();
      _availableOrganizations = querySnapshot.docs
          .map(
            (doc) =>
                OrganizationModel.fromMap(doc.data() as Map<String, dynamic>),
          )
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Помилка завантаження фондів: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _listenToUserApplications() {
    if (_currentAuthUserId == null) return;
    _applicationsSubscription?.cancel();
    if (_user is VolunteerModel) {
      // Для волонтерів - завантаження їх заявок
      _applicationsSubscription = _applicationService
          .getFundraiserApplicationsForVolunteer(_currentAuthUserId!)
          .listen(
            (applications) {
              _userApplications = applications;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = 'Помилка завантаження заявок: $error';
              notifyListeners();
            },
          );
    } else if (_user is OrganizationModel) {
      // Для організацій - завантаження заявок до них
      _applicationsSubscription = _applicationService
          .getFundraiserApplicationsForOrganizer(_currentAuthUserId!)
          .listen(
            (applications) {
              _organizationApplications = applications;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = 'Помилка завантаження заявок: $error';
              notifyListeners();
            },
          );
    }
  }

  // Завантажує схвалені заявки для фонду
  Future<void> loadApprovedApplicationsForOrganization(
    String organizationId,
  ) async {
    try {
      _approvedApplications = await _applicationService
          .getApprovedApplicationsForOrganization(organizationId);
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Помилка завантаження схвалених заявок: $e';
      notifyListeners();
    }
  }

  // Файли
  void setPickedImageFile(File? file) {
    _pickedImageFile = file;
    notifyListeners();
  }

  void setPickedDocuments(List<File> files) {
    _pickedDocuments = files;
    notifyListeners();
  }

  void clearPickedFiles() {
    _pickedImageFile = null;
    _pickedDocuments.clear();
    notifyListeners();
  }

  // Завантаження файлів
  Future<List<String>> uploadSupportingDocuments() async {
    if(_pickedDocuments.isEmpty) return[];
    _isUploadingFiles = true;
    notifyListeners();
    try{
      List<String> documentUrls = [];
      for(int i = 0; i < _pickedDocuments.length;i++){
        final file = _pickedDocuments[i];
        final String fileName = 'applications/documents/${DateTime.now().millisecondsSinceEpoch}_$i${p.extension(file.path)}';
        final Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
        final UploadTask uploadTask = storageRef.putFile(file);
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        documentUrls.add(downloadUrl);
      }
      return documentUrls;
    } catch (e) {
      _errorMessage = 'Помилка завантаження документів: $e';
      return [];
    } finally {
      _isUploadingFiles = false;
      notifyListeners();
    }
  }

  // Створення заявки
  Future<String?> submitApplication({
    required String title,
    required String description,
    required double requiredAmount,
    required List<CategoryChipModel> categories,
    required DateTime deadline,
    required String contactInfo,
    String? organizationId, // null = загальна заявка
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Завантажуємо документи якщо є
      List<String> documentUrls = [];
      if (_pickedDocuments.isNotEmpty) {
        documentUrls = await uploadSupportingDocuments();
        if (documentUrls.length != _pickedDocuments.length) {
          _isLoading = false;
          notifyListeners();
          return 'Не вдалося завантажити всі документи.';
        }
      }

      final applicationRef = FirebaseFirestore.instance
          .collection('fundraiserApplications')
          .doc();

      final application = FundraiserApplicationModel(
        id: applicationRef.id,
        volunteerId: _currentAuthUserId!,
        organizationId: organizationId ?? '', // Порожній рядок для загальної заявки
        title: title,
        categories: categories,
        description: description,
        requiredAmount: requiredAmount,
        deadline: Timestamp.fromDate(deadline),
        supportingDocuments: documentUrls,
        contactInfo: contactInfo,
        status: FundraisingStatus.pending,
        timestamp: Timestamp.now(),
      );

      await _applicationService.submitFundraiserApplication(application);

      clearPickedFiles();
      _isLoading = false;
      notifyListeners();
      return null; // Успіх
    } catch (e) {
      _errorMessage = 'Помилка при створенні заявки: $e';
      _isLoading = false;
      notifyListeners();
      return _errorMessage;
    }
  }

  // Схвалення заявки (для фондів)
  Future<String?> approveApplication(String applicationId) async {
    try {
      await _applicationService.approveFundraisingApplication(applicationId);
      return null; // Успіх
    } catch (e) {
      return 'Помилка при схваленні заявки: $e';
    }
  }

  // Відхилення заявки (для фондів)
  Future<String?> rejectApplication(String applicationId, String reason) async {
    try {
      await _applicationService.rejectFundraisingApplication(applicationId, reason);
      return null; // Успіх
    } catch (e) {
      return 'Помилка при відхиленні заявки: $e';
    }
  }

  // Оновлення статусу заявки
  Future<String?> updateApplicationStatus(
      String applicationId,
      FundraisingStatus status, {
        String? rejectionReason,
      }) async {
    try {
      await _applicationService.updateApplicationStatus(
        applicationId,
        status,
        rejectionReason: rejectionReason,
      );
      return null; // Успіх
    } catch (e) {
      return 'Помилка при оновленні статусу заявки: $e';
    }
  }

  // Масове оновлення статусу заявок (для завершення збору)
  Future<String?> completeApplications(List<String> applicationIds) async {
    try {
      await _applicationService.updateMultipleApplicationsStatus(
        applicationIds,
        FundraisingStatus.completed,
      );
      return null; // Успіх
    } catch (e) {
      return 'Помилка при завершенні заявок: $e';
    }
  }

  @override
  void dispose() {
    _applicationsSubscription?.cancel();
    _approvedApplicationsSubscription?.cancel();
    super.dispose();
  }
}