import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:helphub/data/services/friend_service.dart';
import 'package:helphub/data/services/project_application_service.dart';

import '../../data/services/activity_service.dart';
import '../../data/services/category_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/project_service.dart';
import '../../data/services/skill_service.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/category_chip_model.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/project_application_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_task_model.dart';
import '../../data/models/volunteer_model.dart';

class ProjectViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ProjectService _projectService = ProjectService();
  final CategoryService _categoryService = CategoryService();
  final SkillService _skillService = SkillService();
  final ActivityService _activityService = ActivityService();
  final FriendService _friendService = FriendService();
  final ProjectApplicationService _projectApplicationService =
      ProjectApplicationService();
  final ChatService _chatService = ChatService();

  StreamSubscription<List<ProjectModel>>? _projectsSubscription;
  List<ProjectModel> _allProjects = [];
  List<ProjectModel> _filteredProjects = [];
  String _searchQuery = '';
  List<CategoryChipModel> _selectedCategories = [];
  List<String> _selectedSkills = [];
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  double? _searchRadius;
  bool _isOnlyFriends = false;
  bool _isOnlyOpen = false;

  BaseProfileModel? _user;
  BaseProfileModel? _organizer;
  String? _currentAuthUserId;
  ProjectModel? _currentProject;
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  GeoPoint? _projectCoordinates;
  GeoPoint? _currentUserLocation;
  bool _isGeocodingLoading = false;
  String? _geocodingError;
  List<CategoryChipModel> _availableCategories = [];
  List<CategoryChipModel> _availableSkills = [];

  List<String> _friendsUids = [];

  List<ProjectModel> get filteredProjects => _filteredProjects;

  List<CategoryChipModel> get selectedCategories => _selectedCategories;

  List<String> get selectedSkills => _selectedSkills;

  DateTime? get selectedStartDate => _selectedStartDate;

  DateTime? get selectedEndDate => _selectedEndDate;

  double? get searchRadius => _searchRadius;

  bool get isOnlyFriends => _isOnlyFriends;

  bool get isOnlyOpen => _isOnlyOpen;

  GeoPoint? get currentUserLocation => _currentUserLocation;

  BaseProfileModel? get user => _user;

  BaseProfileModel? get organizer => _organizer;

  ProjectModel? get currentProject => _currentProject;

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  GeoPoint? get projectCoordinates => _projectCoordinates;

  bool get isGeocodingLoading => _isGeocodingLoading;

  String? get geocodingError => _geocodingError;

  List<CategoryChipModel> get availableCategories => _availableCategories;

  List<CategoryChipModel> get availableSkills => _availableSkills;

  String? _projectChatId;

  String? get projectChatId => _projectChatId;
  ProjectViewModel() {
    _init();
  }

  Future<void> _init() async {
    _currentAuthUserId = _auth.currentUser?.uid;
    if (_currentAuthUserId != null) {
      _user = await _fetchCurrentUserProfile(_currentAuthUserId);
      await _fetchCurrentUserFriends();
      await _getCurrentUserLocation();
      _listenToProjects();
    }
    await fetchSkillsAndCategories();
  }

  Future<BaseProfileModel?> _fetchCurrentUserProfile(String? userId) async {
    try {
      if (userId == null) return null;

      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['role'] == 'volunteer') {
          return VolunteerModel.fromMap(data);
        } else if (data['role'] == 'organization') {
          return OrganizationModel.fromMap(data);
        }
      }
    } catch (e) {
      print('Error fetching current user profile in ProjectViewModel: $e');
      _user = null;
    }
    notifyListeners();
    return null;
  }

  Future<void> _fetchCurrentUserFriends() async {
    if (_currentAuthUserId != null) {
      try {
        _friendsUids = await _friendService.getFriendsUids();
      } catch (e) {
        print('Error fetching friends: $e');
        _friendsUids = [];
      }
    }
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

  void _listenToProjects() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _projectsSubscription?.cancel();
    _projectsSubscription = _projectService.fetchProjectsStream().listen(
      (projects) {
        _allProjects =
            projects.where((project) {
              final totalTasks = project.tasks?.length ?? 0;
              if (totalTasks == 0) return false;
              final completedTasks =
                  project.tasks
                      ?.where((t) => t.status == TaskStatus.confirmed)
                      .length ??
                  0;
              final totalNeededPeople = project.tasks
                  ?.map((task) => task.neededPeople ?? 0)
                  .fold<int>(0, (int sum, int count) => sum + count);
              final totalVolunteers = project.tasks
                  ?.map((task) => task.assignedVolunteerIds?.length ?? 0)
                  .fold<int>(0, (int sum, int count) => sum + count);
              final bool isFull =
                  totalVolunteers != null &&
                      totalNeededPeople != null &&
                      totalVolunteers >= totalNeededPeople;
              return (_user == null ||
                      _user!.city == null ||
                      project.city == _user!.city) &&
                  (project.endDate == null ||
                  project.endDate!.isAfter(DateTime.now())) &&
                  completedTasks != totalTasks && !isFull;
            }).toList()..sort(
              (a, b) => (a.startDate ?? DateTime(9999)).compareTo(
                b.startDate ?? DateTime(9999),
              ),
            );
        _isLoading = false;
        _applyFilters();
      },
      onError: (error) {
        _errorMessage = 'Помилка завантаження проєктів: $error';
        _isLoading = false;
        _allProjects = [];
        _filteredProjects = [];
        notifyListeners();
      },
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setFilters(
    List<CategoryChipModel> categories,
    List<String> skills,
    double? radius,
    DateTime? startDate,
    DateTime? endDate,
    bool isOnlyFriends,
    bool isOnlyOpen,
  ) {
    _selectedCategories = categories;
    _selectedSkills = skills;
    _searchRadius = radius;
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    _isOnlyFriends = isOnlyFriends;
    _isOnlyOpen = isOnlyOpen;
    _applyFilters();
  }

  void clearFilters() {
    _selectedCategories = [];
    _selectedSkills = [];
    _selectedStartDate = null;
    _selectedEndDate = null;
    _searchQuery = '';
    _searchRadius = null;
    _isOnlyFriends = false;
    _isOnlyOpen = false;
    _applyFilters();
  }

  void _applyFilters() {
    List<ProjectModel> tempProjects = List.from(_allProjects);

    // Фільтрація за пошуковим запитом
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      tempProjects = tempProjects.where((project) {
        return (project.title?.toLowerCase().contains(queryLower) ?? false) ||
            (project.description?.toLowerCase().contains(queryLower) ??
                false) ||
            (project.locationText?.toLowerCase().contains(queryLower) ?? false);
      }).toList();
    }

    // Фільтрація за категоріями
    if (_selectedCategories.isNotEmpty) {
      tempProjects = tempProjects.where((project) {
        return project.categories?.any(
              (projectCategory) => _selectedCategories.any(
                (selectedCategory) =>
                    selectedCategory.title == projectCategory.title,
              ),
            ) ??
            false;
      }).toList();
    }

    // Фільтрація за навичками
    if (_selectedSkills.isNotEmpty) {
      tempProjects = tempProjects.where((project) {
        return project.skills?.any(
              (projectSkill) => _selectedSkills.contains(projectSkill),
            ) ??
            false;
      }).toList();
    }

    // Фільтрація за датою
    if (_selectedStartDate != null || _selectedEndDate != null) {
      tempProjects = tempProjects.where((project) {
        final projectStartDate = project.startDate;
        final projectEndDate = project.endDate;
        if (projectStartDate == null || projectEndDate == null) return false;
        final startDate = _selectedStartDate;
        final endDate = _selectedEndDate;
        bool matchesStartDate =
            startDate == null ||
            projectStartDate.isAtSameMomentAs(startDate) ||
            projectStartDate.isAfter(startDate);
        bool matchesEndtDate =
            endDate == null ||
            projectEndDate.isAtSameMomentAs(endDate) ||
            projectEndDate.isBefore(endDate);
        return matchesStartDate && matchesEndtDate;
      }).toList();
    }
    // Фільтрація за локацією (радіус)
    if (_currentUserLocation != null &&
        _searchRadius != null &&
        _searchRadius! > 0) {
      tempProjects = tempProjects.where((project) {
        if (project.locationGeo == null) return false;
        final double distanceInMeters = Geolocator.distanceBetween(
          _currentUserLocation!.latitude,
          _currentUserLocation!.longitude,
          project.locationGeo!.latitude,
          project.locationGeo!.longitude,
        );
        final double searchRadiusMeters = _searchRadius! * 1000;
        return distanceInMeters <= searchRadiusMeters;
      }).toList();
    }

    // Фільтрація за "Тільки для друзів"
    if (_isOnlyFriends) {
      tempProjects = tempProjects.where((project) {
        return project.organizerId != null &&
            _friendsUids.contains(project.organizerId);
      }).toList();
    }

    // Фільтрація за "Тільки відкриті проєкти"
    if (_isOnlyOpen) {
      tempProjects = tempProjects.where((project) {
        final projectEndDate = project.endDate;
        return projectEndDate == null || projectEndDate.isAfter(DateTime.now());
      }).toList();
    }

    _filteredProjects = tempProjects;
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
        _organizer = await _fetchCurrentUserProfile(
          _currentProject!.organizerId!,
        );
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

      final chatId = await _chatService.createProjectChat(
        newProject.id!,
        [_currentAuthUserId!],
      );

      if (chatId != null) {
        _projectChatId = chatId;
      }
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

  Future<String?> applyToProject({
    required String projectId,
    required List<ProjectTaskModel> selectedTasks,
    required Map<String, String> messages,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    if (_currentAuthUserId == null || _user == null) {
      _isSubmitting = false;
      notifyListeners();
      return 'Користувач не авторизований. Будь ласка, увійдіть.';
    }

    if (selectedTasks.isEmpty) {
      _isSubmitting = false;
      notifyListeners();
      return 'Будь ласка, оберіть хоча б одне завдання для участі.';
    }

    try {
      for (var task in selectedTasks) {
        final newApplication = ProjectApplicationModel(
          id: _firestore.collection('projectApplications').doc().id,
          volunteerId: _currentAuthUserId!,
          projectId: projectId,
          taskId: task.id,
          message: messages[task.id!],
          status: 'pending',
          timestamp: Timestamp.now(),
        );
        await _projectApplicationService.submitProjectApplication(
          newApplication,
        );
      }

      _isSubmitting = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Помилка при подачі заявки: $e';
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
      List<geocoding.Location> locations = await geocoding.locationFromAddress(
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

  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _currentUserLocation = null;
      notifyListeners();
      return;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _currentUserLocation = null;
        notifyListeners();
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _currentUserLocation = null;
      notifyListeners();
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    _currentUserLocation = GeoPoint(position.latitude, position.longitude);
    notifyListeners();
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
