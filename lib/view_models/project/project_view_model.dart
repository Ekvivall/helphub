
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding/geocoding.dart' as geocoding;

import '../../core/services/activity_service.dart';
import '../../core/services/category_service.dart';
import '../../core/services/project_service.dart';
import '../../core/services/skill_service.dart';
import '../../models/activity_model.dart';
import '../../models/base_profile_model.dart';
import '../../models/category_chip_model.dart';
import '../../models/organization_model.dart';
import '../../models/project_model.dart';
import '../../models/project_task_model.dart';
import '../../models/volunteer_model.dart';

class ProjectViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProjectService _projectService = ProjectService();
  final CategoryService _categoryService = CategoryService();
  final SkillService _skillService = SkillService();
  final ActivityService _activityService = ActivityService();

  BaseProfileModel? _user;
  String? _currentAuthUserId;
  ProjectModel? _currentProject;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  GeoPoint? _projectCoordinates;
  bool _isGeocodingLoading = false;
  String? _geocodingError;
  List<CategoryChipModel> _availableCategories = [];
  List<CategoryChipModel> _availableSkills = [];

  BaseProfileModel? get user => _user;

  ProjectModel? get currentProject => _currentProject;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;


  GeoPoint? get projectCoordinates => _projectCoordinates;

  bool get isGeocodingLoading => _isGeocodingLoading;

  String? get geocodingError => _geocodingError;

  List<CategoryChipModel> get availableCategories => _availableCategories;

  List<CategoryChipModel> get availableSkills => _availableSkills;

  ProjectViewModel() {
    _init();
  }

  Future<void> _init() async {
    _currentAuthUserId = _auth.currentUser?.uid;
    if (_currentAuthUserId != null) {
      await _fetchCurrentUserProfile();
    }
  }

  Future<void> _fetchCurrentUserProfile() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['role'] == 'volunteer') {
          _user = VolunteerModel.fromMap(data);
        } else if (data['role'] == 'organization') {
          _user = OrganizationModel.fromMap(data);
        }
      }
    } catch (e) {
      print('Error fetching current user profile in ProjectViewModel: $e');
      _user = null;
    }
    notifyListeners();
  }

  Future<void> fetchSkillsAndCategories() async {
    _isLoading = true;
    notifyListeners();
    try {
      _availableCategories = await _categoryService.fetchCategories();
      _availableSkills = await _skillService.fetchSkills();
      _isLoading = false;
    } catch (e) {
      _errorMessage = 'Не вдалося завантажити навички та категорії: $e';
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> loadProjectDetails(String projectId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _currentProject = await _projectService.getProjectById(projectId);
      if (_currentProject == null) {
        _errorMessage = 'Проект не знайдено.';
      } else {
        _projectCoordinates = _currentProject!.locationGeo;
      }
    } catch (e) {
      _errorMessage = 'Помилка завантаження проекту: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<String?> createProject({
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required List<CategoryChipModel> categories,
    required List<String> skills,
    required List<ProjectTaskModel> tasks,
    required String city,
    required bool isOnlyFriends,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    if (_user == null || _currentAuthUserId == null) {
      _isSubmitting = false;
      notifyListeners();
      return 'Користувач не авторизований. Будь ласка, увійдіть.';
    }

    try {
      final newProjectRef = _firestore.collection('projects').doc();

      final newProject = ProjectModel(
        id: newProjectRef.id,
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        organizerId: _currentAuthUserId!,
        organizerName: _user is VolunteerModel
            ? (_user as VolunteerModel).fullName ??
            (_user as VolunteerModel).displayName ??
            'Волонтер'
            : _user is OrganizationModel
            ? (_user as OrganizationModel).organizationName ?? 'Фонд'
            : 'Невідомий користувач',
        city: _user!.city ?? city,
        timestamp: DateTime.now(),
        tasks: tasks,
        locationText: location,
        locationGeo: _projectCoordinates,
        skills: skills,
        isOnlyFriends: isOnlyFriends,
        reportId: null,
      );

      await _firestore.runTransaction((transaction) async {
        final userDocRef = _firestore
            .collection('users')
            .doc(_currentAuthUserId);

        final userSnapshot = await transaction.get(userDocRef);

        transaction.set(newProjectRef, newProject.toMap());

        if (userSnapshot.exists) {
          int currentProjectsCount =
              (userSnapshot.data()?['projectsCount'] as int?) ?? 0;
          transaction.update(userDocRef, {
            'projectsCount': currentProjectsCount + 1,
          });
        }
      });

      final activity = ActivityModel(
        type: ActivityType.projectOrganization,
        entityId: newProject.id!,
        title: newProject.title!,
        description: newProject.description,
        timestamp: DateTime.now(),
      );
      await _activityService.logActivity(_currentAuthUserId!, activity);

      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Помилка при створенні проекту: $e';
      _isSubmitting = false;
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<String?> updateProject({
    required String projectId,
    required String title,
    required String description,
    required String location,
    required DateTime startDate,
    required DateTime endDate,
    required List<CategoryChipModel> categories,
    required List<String> skills,
    required List<ProjectTaskModel> tasks,
    required String city,
    required bool isOnlyFriends,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    if (_currentProject == null) {
      _isSubmitting = false;
      notifyListeners();
      return 'Не вдалося знайти проект для оновлення.';
    }

    try {
      final updatedProject = _currentProject!.copyWith(
        title: title,
        description: description,
        startDate: startDate,
        endDate: endDate,
        categories: categories,
        skills: skills,
        tasks: tasks,
        locationText: location,
        locationGeo: _projectCoordinates,
        city: _user!.city ?? city,
        isOnlyFriends: isOnlyFriends,
      );
      await _projectService.updateProject(updatedProject);
      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Помилка при оновленні проекту: $e';
      _isSubmitting = false;
      notifyListeners();
      return _errorMessage;
    }
  }

  Future<void> geocodeAddress(String address, String city) async {
    _isGeocodingLoading = true;
    _geocodingError = null;
    notifyListeners();
    try {
      List<Location> locations = await geocoding.locationFromAddress(
        '$address, $city, Ukraine',
      );
      if (locations.isNotEmpty) {
        _projectCoordinates = GeoPoint(
          locations.first.latitude,
          locations.first.longitude,
        );
        _geocodingError = null;
      } else {
        _projectCoordinates = null;
        _geocodingError = 'Координати не знайдено для цієї адреси.';
      }
    } catch (e) {
      _projectCoordinates = null;
      _geocodingError = 'Помилка геолокації: $e';
      print('Error geocoding address: $e');
    } finally {
      _isGeocodingLoading = false;
      notifyListeners();
    }
  }

  void setProjectCoordinates(double lat, double lng) {
    _projectCoordinates = GeoPoint(lat, lng);
    _geocodingError = null;
    notifyListeners();
  }

  void clearProjectCoordinates() {
    _projectCoordinates = null;
    _geocodingError = null;
    notifyListeners();
  }


  @override
  void dispose() {
    super.dispose();
  }
}
