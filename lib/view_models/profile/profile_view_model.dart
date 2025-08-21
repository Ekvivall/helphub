import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:helphub/core/services/category_service.dart';
import 'package:helphub/core/services/follow_service.dart';
import 'package:helphub/core/services/friend_service.dart';
import 'package:helphub/core/services/fundraiser_application_service.dart';
import 'package:helphub/core/services/fundraising_service.dart';
import 'package:helphub/core/services/project_application_service.dart';
import 'package:helphub/core/services/project_service.dart';
import 'package:helphub/core/utils/user_role_extension.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/friend_request_model.dart';
import 'package:helphub/models/fundraising_model.dart';
import 'package:helphub/models/fundraiser_application_model.dart';
import 'package:helphub/models/organization_model.dart';
import 'package:helphub/models/project_application_model.dart';
import 'package:helphub/models/volunteer_model.dart';

import '../../core/services/event_service.dart';
import '../../models/event_model.dart';
import '../../models/project_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CategoryService _categoryService = CategoryService();
  final FriendService _friendService = FriendService();
  final FundraisingService _fundraiserService = FundraisingService();
  final ProjectApplicationService _projectApplicationService =
      ProjectApplicationService();
  final FundraiserApplicationService _fundraiserApplicationService =
      FundraiserApplicationService();
  final FollowService _followService = FollowService();
  final ProjectService _projectService = ProjectService();

  BaseProfileModel? _user; // Поточні дані користувача
  bool _isLoading = false;
  bool _isEditing = false;
  String? _selectedCity;
  List<CategoryChipModel> _availableInterests = [];
  List<CategoryChipModel> _selectedInterests = [];

  List<FundraisingModel> _savedFundraisers = [];
  StreamSubscription<List<FundraisingModel>>? _savedFundraiserSubscription;
  List<ProjectApplicationModel> _volunteerProjectApplications = [];
  List<FundraiserApplicationModel> _volunteerFundraiserApplications = [];
  List<FundraiserApplicationModel> _organizationFundraiserApplications = [];
  StreamSubscription<List<ProjectApplicationModel>>?
  _projectApplicationsForVolunteerSubscription;
  StreamSubscription<List<FundraiserApplicationModel>>?
  _fundraiserApplicationsForVolunteerSubscription;
  StreamSubscription<List<FundraiserApplicationModel>>?
  _fundraiserApplicationsForOrganizationSubscription;

  FriendshipStatus _friendshipStatus = FriendshipStatus.self;
  List<FriendRequestModel> _incomingFriendRequests = [];
  List<String> _friendsList = [];
  List<VolunteerModel> _friendProfiles = [];
  StreamSubscription? _incomingRequestsSubscription;
  StreamSubscription? _friendsListSubscription;

  bool? _isFollowing;
  int _followersCount = 0;
  StreamSubscription<bool>? _isFollowingSubscription;
  StreamSubscription<int>? _followersCountSubscription;
  List<OrganizationModel> _followedOrganizations = [];
  StreamSubscription<List<String>>? _followingOrganizationsSubscription;
  List<VolunteerModel> _filteredFriendProfiles = [];
  List<OrganizationModel> _filteredFollowedOrganizations = [];
  String _currentFriendSearchQuery = '';
  String _currentFollowedOrgSearchQuery = '';

  List<ActivityModel> _latestActivities = [];
  bool _isActivitiesLoading = false;
  String? _activitiesError;

  late TextEditingController fullNameController;
  late TextEditingController organizationNameController;
  late TextEditingController websiteController;
  late TextEditingController aboutMeController;
  late TextEditingController nicknameController;
  late TextEditingController phoneNumberController;
  late TextEditingController telegramLinkController;
  late TextEditingController instagramLinkController;

  List<VolunteerModel> _searchResults = [];
  bool _isSearching = false;
  String? _searchError; // Для повідомлень про помилки пошуку
  List<VolunteerModel> get searchResults => _searchResults;

  bool get isSearching => _isSearching;

  String? get searchError => _searchError;

  BaseProfileModel? get user => _user;

  bool get isLoading => _isLoading;

  bool get isEditing => _isEditing;

  String? get selectedCity => _selectedCity;

  List<CategoryChipModel> get availableInterests => _availableInterests;

  List<CategoryChipModel> get selectedInterests => _selectedInterests;

  FriendshipStatus get friendshipStatus => _friendshipStatus;

  List<FriendRequestModel> get incomingFriendRequests =>
      _incomingFriendRequests;

  List<String> get friendsList => _friendsList;

  List<VolunteerModel> get friendProfiles => _friendProfiles;

  int get incomingFriendRequestsCount => _incomingFriendRequests.length;

  List<FundraisingModel> get savedFundraiser => _savedFundraisers;

  List<ProjectApplicationModel> get volunteerProjectApplications =>
      _volunteerProjectApplications;

  List<FundraiserApplicationModel> get volunteerFundraiserApplications =>
      _volunteerFundraiserApplications;

  List<FundraiserApplicationModel> get organizationFundraiserApplications =>
      _organizationFundraiserApplications;

  bool? get isFollowing => _isFollowing;

  int get followersCount => _followersCount;

  List<OrganizationModel> get followedOrganizations => _followedOrganizations;

  List<VolunteerModel> get filteredFriendProfiles {
    if (_currentFriendSearchQuery.isEmpty) {
      return _friendProfiles;
    }
    return _filteredFriendProfiles;
  }

  List<OrganizationModel> get filteredFollowedProfiles {
    if (_currentFollowedOrgSearchQuery.isEmpty) {
      return _followedOrganizations;
    }
    return _filteredFollowedOrganizations;
  }

  List<ActivityModel> get latestActivities => _latestActivities;

  bool get isActivitiesLoading => _isActivitiesLoading;

  String? get activitiesError => _activitiesError;

  final String? _viewingUserId; // ID користувача, який переглядається
  String? _currentAuthUserId; // UID поточного авторизованого користувача
  String? get currentAuthUserId => _currentAuthUserId;
  UserRole? _currentUserRole;

  UserRole? get currentUserRole => _currentUserRole;

  String? get viewingUserId => _viewingUserId;
  Map<String, ProjectModel> _projectsData = {};

  Map<String, ProjectModel> get projectsData => _projectsData;
  Map<String, ProjectModel> _projectsDataActivities = {};

  Map<String, ProjectModel> get projectsDataActivities => _projectsDataActivities;
  Map<String, EventModel> _eventsData = {};
  Map<String, FundraisingModel> _fundraisingsData = {};

  Map<String, EventModel> get eventsData => _eventsData;

  Map<String, FundraisingModel> get fundraisingsData => _fundraisingsData;
  List<FundraisingModel> _activeFundraisings = [];
  StreamSubscription<List<FundraisingModel>>? _activeFundraisingsSubscription;

  List<FundraisingModel> get activeFundraisings => _activeFundraisings;

  ProfileViewModel({String? viewingUserId}) : _viewingUserId = viewingUserId {
    fullNameController = TextEditingController();
    organizationNameController = TextEditingController();
    websiteController = TextEditingController();
    aboutMeController = TextEditingController();
    nicknameController = TextEditingController();
    phoneNumberController = TextEditingController();
    telegramLinkController = TextEditingController();
    instagramLinkController = TextEditingController();

    // Автоматичне завантаження профілю при ініціалізації ViewModel
    // Якщо ще не завантажено
    _auth.authStateChanges().listen((user) async {
      _currentAuthUserId = user?.uid;
      fetchUserProfile();
      if (_viewingUserId != null && _viewingUserId != _currentAuthUserId) {
        BaseProfileModel? user = await fetchUser(_currentAuthUserId);
        _currentUserRole = user?.role;
      }
    });
  }

  @override
  void dispose() {
    fullNameController.dispose();
    organizationNameController.dispose();
    websiteController.dispose();
    aboutMeController.dispose();
    nicknameController.dispose();
    phoneNumberController.dispose();
    telegramLinkController.dispose();
    instagramLinkController.dispose();
    _incomingRequestsSubscription?.cancel();
    _friendsListSubscription?.cancel();
    _savedFundraiserSubscription?.cancel();
    _projectApplicationsForVolunteerSubscription?.cancel();
    _fundraiserApplicationsForVolunteerSubscription?.cancel();
    _fundraiserApplicationsForOrganizationSubscription?.cancel();
    _followersCountSubscription?.cancel();
    _isFollowingSubscription?.cancel();
    _followingOrganizationsSubscription?.cancel();
    _listenToActiveFundraisings(_user!.uid!);
    super.dispose();
  }

  void updateCity(String newValue) {
    _selectedCity = newValue;
    notifyListeners();
  }

  Future<void> fetchUserProfile() async {
    _setLoading(true);
    try {
      final String? uidToFetch = _viewingUserId ?? _auth.currentUser?.uid;
      if (uidToFetch == null) {
        _user = null;
        return;
      }
      final doc = await _firestore.collection('users').doc(uidToFetch).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        final roleString = data?['role'] as String?;
        await fetchAllActivities(uidToFetch);
        if (roleString == UserRole.volunteer.name) {
          _user = VolunteerModel.fromMap(doc.data()!);
          if (viewingUserId == null ||
              viewingUserId == _auth.currentUser!.uid) {
            _listenToFriendRelatedData();
            _listenToSavedFundraisers();
            _listenToProjectApplicationsForVolunteer(_user!.uid!);
            _listenToFundraiserApplicationsForVolunteer(_user!.uid!);
            _listenToFollowingOrganizations(_user!.uid!);
          }
        } else {
          _user = OrganizationModel.fromMap(doc.data()!);
          if (viewingUserId == null ||
              viewingUserId == _auth.currentUser!.uid) {
            _listenToFundraiserApplicationsForOrganization(_user!.uid!);
            _listenToFollowersCount(_user!.uid!);
            _listenToActiveFundraisings(_user!.uid!);
          } else {
            _listenToIsFollowing(_auth.currentUser!.uid, uidToFetch);
            _listenToFollowersCount(_user!.uid!);
          }
        }
        if (uidToFetch == _currentAuthUserId) {
          _fillControllersFromUser();
        } else {
          _friendshipStatus = await getFriendshipStatus(uidToFetch);
          notifyListeners();
        }
        await _loadCategories();
      } else {
        _user = null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<FriendshipStatus> getFriendshipStatus(String targetUserId) async {
    if (_currentAuthUserId == null) {
      return FriendshipStatus.notFriends;
    }
    if (targetUserId == _currentAuthUserId) {
      return FriendshipStatus.self;
    }
    //Check if they are already friends
    if (await _friendService.areFriends(currentAuthUserId!, targetUserId)) {
      return FriendshipStatus.friends;
    }
    // Check for an outgoing request from current user to viewing user
    if (await _friendService.hasSentFriendRequest(
      currentAuthUserId,
      targetUserId,
    )) {
      return FriendshipStatus.requestSent;
    }
    // Check for an incoming request from viewing user to current user
    if (await _friendService.hasReceivedFriendRequest(
      currentAuthUserId,
      targetUserId,
    )) {
      return FriendshipStatus.requestReceived;
    }
    // Else, they are not friends
    return FriendshipStatus.notFriends;
  }

  void _listenToFriendRelatedData() {
    _incomingRequestsSubscription?.cancel();
    _friendsListSubscription?.cancel();
    if (_currentAuthUserId != null && user?.role == UserRole.volunteer) {
      _incomingRequestsSubscription = _friendService
          .listenToIncomingRequests()
          .listen((requests) {
            _incomingFriendRequests = requests;
            notifyListeners();
          });
      _friendsListSubscription = _friendService.getFriendList().listen((
        friends,
      ) {
        _friendsList = friends;
        _fetchFriendProfiles();
        notifyListeners();
      });
    }
  }

  Future<void> _fetchFriendProfiles() async {
    if (_friendsList.isEmpty) {
      _friendProfiles = [];
      notifyListeners();
      return;
    }
    List<VolunteerModel> fetchedProfiles = [];
    for (String friendUid in _friendsList) {
      try {
        final doc = await _firestore.collection('users').doc(friendUid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          fetchedProfiles.add(VolunteerModel.fromMap(data));
        }
      } catch (e) {
        debugPrint('Error fetching friend profile for $friendUid: $e');
      }
    }
    _friendProfiles = fetchedProfiles;
    _filteredFriendProfiles = List.from(fetchedProfiles);
    notifyListeners();
  }

  Future<void> sendFriendRequest(String uid) async {
    try {
      _setLoading(true);
      await _friendService.sendFriendRequest(uid);
    } catch (e) {
      print('Error sending friend request: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptFriendRequestFromUser(String userId) async {
    try {
      _setLoading(true);
      await _friendService.acceptFriendRequest(userId);
      // Refetch profile to ensure friend list is updated immediately
      await fetchUserProfile();
    } catch (e) {
      print('Error accepting friend request: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectFriendRequestFromUser(String uid) async {
    try {
      _setLoading(true);
      await _friendService.rejectFriendRequest(uid);
    } catch (e) {
      print('Error rejecting friend request: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unfriendViewingUser(String uid) async {
    try {
      _setLoading(true);
      await _friendService.unfriend(uid);
      await fetchUserProfile();
    } catch (e) {
      print('Error unfriending user: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateUserData() async {
    if (_user == null) return false;
    _setLoading(true);
    try {
      BaseProfileModel updatedUser;
      if (_user is VolunteerModel) {
        final String newDisplayName = nicknameController.text.trim();
        if (newDisplayName.isNotEmpty &&
            newDisplayName != (_user as VolunteerModel).displayName) {
          bool isUnique = await isDisplayNameUnique(newDisplayName);
          if (!isUnique) {
            _setLoading(false);
            return false;
          }
        }
        updatedUser = (_user as VolunteerModel).copyWith(
          fullName: fullNameController.text.trim().isNotEmpty
              ? fullNameController.text.trim()
              : null,
          city: _selectedCity,
          aboutMe: aboutMeController.text.trim().isNotEmpty
              ? aboutMeController.text.trim()
              : null,
          displayName: newDisplayName.isNotEmpty ? newDisplayName : null,
          phoneNumber: phoneNumberController.text.trim().isNotEmpty
              ? phoneNumberController.text.trim()
              : null,
          telegramLink: telegramLinkController.text.trim().isNotEmpty
              ? telegramLinkController.text.trim()
              : null,
          instagramLink: instagramLinkController.text.trim().isNotEmpty
              ? instagramLinkController.text.trim()
              : null,
          categoryChips: selectedInterests.isNotEmpty
              ? _selectedInterests
              : null,
        );
      } else if (_user is OrganizationModel) {
        updatedUser = (_user as OrganizationModel).copyWith(
          organizationName: organizationNameController.text.trim().isNotEmpty
              ? organizationNameController.text.trim()
              : null,
          website: websiteController.text.trim().isNotEmpty
              ? websiteController.text.trim()
              : null,
          city: _selectedCity,
          aboutMe: aboutMeController.text.trim().isNotEmpty
              ? aboutMeController.text.trim()
              : null,
          phoneNumber: phoneNumberController.text.trim().isNotEmpty
              ? phoneNumberController.text.trim()
              : null,
          telegramLink: telegramLinkController.text.trim().isNotEmpty
              ? telegramLinkController.text.trim()
              : null,
          instagramLink: instagramLinkController.text.trim().isNotEmpty
              ? instagramLinkController.text.trim()
              : null,
          categoryChips: selectedInterests.isNotEmpty
              ? _selectedInterests
              : null,
        );
      } else {
        return false;
      }
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .set(updatedUser.toMap(), SetOptions(merge: true));
      _user = updatedUser;
      _isEditing = false;
    } catch (e) {
      print('Error updating user data: $e');
    } finally {
      _setLoading(false);
    }
    return true;
  }

  Future<void> updateProfilePhoto(File imageFile) async {
    if (_user == null || _user!.uid == null) {
      return;
    }
    _setLoading(true);
    try {
      final String userId = _user!.uid!;
      final String fileName = 'profile_photos/$userId/profile.jpg';
      final Reference storageRef = _storage.ref().child(fileName);
      try {
        await storageRef.delete();
      } catch (e) {}
      await storageRef.putFile(imageFile);
      final String downloadUrl = await storageRef.getDownloadURL();
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': downloadUrl,
      });
      if (_user is VolunteerModel) {
        _user = (_user as VolunteerModel).copyWith(photoUrl: downloadUrl);
      } else if (_user is OrganizationModel) {
        _user = (_user as OrganizationModel).copyWith(photoUrl: downloadUrl);
      }
    } finally {
      _setLoading(false);
    }
  }

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _fillControllersFromUser() {
    if (_user is VolunteerModel) {
      final volunteer = _user as VolunteerModel;
      fullNameController.text = volunteer.fullName ?? '';
      nicknameController.text = volunteer.displayName ?? '';
      aboutMeController.text = volunteer.aboutMe ?? '';
      nicknameController.text = volunteer.displayName ?? '';
      phoneNumberController.text = volunteer.phoneNumber ?? '';
      telegramLinkController.text = volunteer.telegramLink ?? '';
      instagramLinkController.text = volunteer.instagramLink ?? '';
      _selectedInterests = _user?.categoryChips ?? [];
      // Clear organization specific controllers
      organizationNameController.text = '';
      websiteController.text = '';
      _selectedCity = volunteer.city;
    } else if (_user is OrganizationModel) {
      final organization = _user as OrganizationModel;
      organizationNameController.text = organization.organizationName ?? '';
      websiteController.text = organization.website ?? '';
      aboutMeController.text = organization.aboutMe ?? '';
      phoneNumberController.text = organization.phoneNumber ?? '';
      telegramLinkController.text = organization.telegramLink ?? '';
      instagramLinkController.text = organization.instagramLink ?? '';
      _selectedInterests = _user?.categoryChips ?? [];
      // Clear volunteer specific controllers
      fullNameController.text = '';
      _selectedCity = organization.city;
      nicknameController.text = '';
    } else {
      // Clear all if user is null or unknown type
      fullNameController.text = '';
      nicknameController.text = '';
      organizationNameController.text = '';
      websiteController.text = '';
      aboutMeController.text = '';
      _selectedCity = null;
    }
    notifyListeners();
  }

  Future<bool> isDisplayNameUnique(String displayName) async {
    if (displayName.trim().isEmpty) {
      return false;
    }
    final querySnapshot = await _firestore
        .collection('users')
        .where('displayName', isEqualTo: displayName.trim())
        .limit(1)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  Future<void> searchUsers(String query) async {
    _isSearching = true;
    _searchResults = [];
    _searchError = null;
    notifyListeners();
    if (query.trim().isEmpty) {
      _isSearching = false;
      notifyListeners();
      return;
    }
    try {
      // Пошук за нікнеймом
      QuerySnapshot displayNameResults = await _firestore
          .collection('users')
          .orderBy('displayName')
          .startAt([query.trim()])
          .endAt(['${query.trim()}\uf8ff'])
          .get();
      // Пошук за повним ім'ям
      QuerySnapshot fullNameResults = await _firestore
          .collection('users')
          .orderBy('fullName')
          .startAt([query.trim()])
          .endAt(['${query.trim()}\uf8ff'])
          .get();
      Set<VolunteerModel> uniqueResults = {};
      for (var doc in displayNameResults.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userRole = (data['role'] as String?)?.toUserRole();
        if (userRole == UserRole.volunteer) {
          uniqueResults.add(VolunteerModel.fromMap(data));
        }
      }
      for (var doc in fullNameResults.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final userRole = (data['role'] as String?)?.toUserRole();
        if (userRole == UserRole.volunteer) {
          uniqueResults.add(VolunteerModel.fromMap(data));
        }
      }
      _searchResults = uniqueResults
          .where((user) => user.uid != _currentAuthUserId)
          .toList();
      if (_searchResults.isEmpty) {
        _searchError = 'Користувачів за запитом "${query.trim()}" не знайдено.';
      }
    } catch (e) {
      _searchError = 'Помилка під час пошуку користувачів. Спробуйте пізніше.';
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  void toggleInterest(CategoryChipModel interest) {
    final existingInterestIndex = _selectedInterests.indexWhere(
      (element) => element.title == interest.title,
    );
    if (existingInterestIndex != -1) {
      _selectedInterests.removeAt(existingInterestIndex);
    } else {
      _selectedInterests.add(interest);
    }
    notifyListeners();
  }

  void cancelEditing() {
    _isEditing = false;
    _fillControllersFromUser();
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    _setLoading(true);
    _availableInterests = await _categoryService.fetchCategories();
    _setLoading(false);
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  Future<void> saveFundraiser(String fundId) async {
    if (_user?.uid != null) {
      try {
        await _fundraiserService.saveFundraiser(_user!.uid!, fundId);
        notifyListeners();
      } catch (e) {
        print('Error saving fundraiser in ViewModel: $e');
      }
    }
  }

  Future<void> unsaveFundraiser(String fundId) async {
    if (_user?.uid != null) {
      try {
        await _fundraiserService.unsaveFundraiser(_user!.uid!, fundId);
        notifyListeners();
      } catch (e) {
        print('Error unsaving fundraiser in ViewModel: $e');
      }
    }
  }

  void _listenToSavedFundraisers() {
    _savedFundraiserSubscription?.cancel();
    if (_user?.uid != null) {
      _savedFundraiserSubscription = _fundraiserService
          .getSavedFundraisers(_user!.uid!)
          .listen(
            (fundraisers) {
              _savedFundraisers = fundraisers
                ..sort((a, b) {
                  // Пріоритет для термінових зборів
                  final isAUrgent = a.isUrgent ?? false;
                  final isBUrgent = b.isUrgent ?? false;

                  if (isAUrgent && !isBUrgent) {
                    return -1;
                  }
                  if (!isAUrgent && isBUrgent) {
                    return 1;
                  }

                  // сортуємо за часом (новіші перші)
                  final aTimestamp = a.timestamp ?? DateTime(1970);
                  final bTimestamp = b.timestamp ?? DateTime(1970);

                  return bTimestamp.compareTo(aTimestamp);
                });
              notifyListeners();
            },
            onError: (error) {
              print('Error listening to saved fundraisers: $error');
            },
          );
    }
  }

  Future<void> submitProjectApplication({
    required String projectId,
    String? taskId,
    String? message,
  }) async {
    if (_user?.uid == null) {
      return;
    }
    _setLoading(true);
    try {
      final newApplication = ProjectApplicationModel(
        id: _firestore.collection('projectApplications').doc().id,
        volunteerId: _user!.uid!,
        projectId: projectId,
        taskId: taskId,
        message: message,
        timestamp: Timestamp.now(),
      );
      await _projectApplicationService.submitProjectApplication(newApplication);
      notifyListeners();
    } catch (e) {
      print('Error submitting project application: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> submitFundraiserApplication({
    required String organizationId,
    required String title,
    required List<CategoryChipModel> categories,
    required String description,
    required double requiredAmount,
    required Timestamp deadline,
    List<String>? supportingDocuments,
    required String contactInfo,
  }) async {
    if (_user?.uid == null) {
      return;
    }
    _setLoading(true);
    try {
      final newApplication = FundraiserApplicationModel(
        id: _firestore.collection('fundraiserApplications').doc().id,
        volunteerId: _user!.uid!,
        organizationId: organizationId,
        title: title,
        categories: categories,
        description: description,
        requiredAmount: requiredAmount,
        deadline: deadline,
        supportingDocuments: supportingDocuments,
        contactInfo: contactInfo,
        timestamp: Timestamp.now(),
      );
      await _fundraiserApplicationService.submitFundraiserApplication(
        newApplication,
      );
      notifyListeners();
    } catch (e) {
      print('Error submitting fundraiser application: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _listenToProjectApplicationsForVolunteer(String volunteerUid) {
    _projectApplicationsForVolunteerSubscription?.cancel();
    _projectApplicationsForVolunteerSubscription = _projectApplicationService
        .getProjectApplicationsForVolunteer(volunteerUid)
        .listen((applications) async {
          _volunteerProjectApplications = applications;
          final projectIds = applications.map((app) => app.projectId).toSet();
          final projects = await Future.wait(
            projectIds.map((id) => _projectService.getProjectById(id)),
          );
          _projectsData = {
            for (var project in projects.where((p) => p != null))
              project!.id!: project,
          };
          notifyListeners();
        });
  }

  void _listenToFundraiserApplicationsForVolunteer(String volunteerUid) {
    _fundraiserApplicationsForVolunteerSubscription?.cancel();
    _fundraiserApplicationsForVolunteerSubscription =
        _fundraiserApplicationService
            .getFundraiserApplicationsForVolunteer(volunteerUid)
            .listen((applications) {
              _volunteerFundraiserApplications = applications;
              notifyListeners();
            });
  }

  void _listenToFundraiserApplicationsForOrganization(String organizationUid) {
    _fundraiserApplicationsForOrganizationSubscription?.cancel();
    _fundraiserApplicationsForOrganizationSubscription =
        _fundraiserApplicationService
            .getFundraiserApplicationsForOrganizer(organizationUid)
            .listen((applications) {
              _organizationFundraiserApplications = applications;
              notifyListeners();
            });
  }

  Future<void> toggleFollow(String organizationUid) async {
    if (_auth.currentUser?.uid == null) {
      return;
    }
    final volunteerUid = _auth.currentUser!.uid;
    _setLoading(true);
    try {
      if (_isFollowing == true) {
        await _followService.unfollowOrganization(
          volunteerUid,
          organizationUid,
        );
        _isFollowing = false;
      } else if (_isFollowing == false) {
        await _followService.followOrganization(volunteerUid, organizationUid);
        _isFollowing = true;
      }
    } catch (e) {
      print('Error toggling follow status: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _listenToFollowersCount(String organizationUid) {
    _followersCountSubscription?.cancel();
    _followersCountSubscription = _followService
        .getFollowersCount(organizationUid)
        .listen((count) {
          _followersCount = count;
          notifyListeners();
        });
  }

  void _listenToIsFollowing(String volunteerUid, String organizationUid) {
    _isFollowingSubscription?.cancel();
    _isFollowingSubscription = _followService
        .isFollowing(volunteerUid, organizationUid)
        .listen((status) {
          _isFollowing = status;
          notifyListeners();
        });
  }

  void _listenToFollowingOrganizations(String volunteerUid) {
    _followingOrganizationsSubscription?.cancel();
    _followingOrganizationsSubscription = _followService
        .getFollowingOrganizations(volunteerUid)
        .listen((organizationUids) async {
          if (organizationUids.isEmpty) {
            _followedOrganizations = [];
            _filteredFollowedOrganizations = [];
            notifyListeners();
            return;
          }
          List<OrganizationModel> organizations = [];
          for (String orgUid in organizationUids) {
            try {
              DocumentSnapshot orgDoc = await _firestore
                  .collection('users')
                  .doc(orgUid)
                  .get();
              if (orgDoc.exists &&
                  (orgDoc.data() as Map<String, dynamic>)['role'] ==
                      UserRole.organization.name) {
                organizations.add(
                  OrganizationModel.fromMap(
                    orgDoc.data() as Map<String, dynamic>,
                  ),
                );
              }
            } catch (e) {
              print('Error fetching organization $orgUid: $e');
            }
          }
          _followedOrganizations = organizations;
          _filteredFollowedOrganizations = List.from(organizations);
          notifyListeners();
        });
  }

  void searchFriends(String query) {
    _currentFriendSearchQuery = query.toLowerCase();
    if (query.isEmpty) {
      _filteredFriendProfiles = List.from(_friendProfiles);
    } else {
      _filteredFriendProfiles = _friendProfiles.where((friend) {
        final fullName = friend.fullName?.toLowerCase() ?? '';
        final displayName = friend.displayName?.toLowerCase() ?? '';
        final city = friend.city?.toLowerCase() ?? '';
        return fullName.contains(_currentFriendSearchQuery) ||
            displayName.contains(_currentFriendSearchQuery) ||
            city.contains(_currentFriendSearchQuery);
      }).toList();
    }
    notifyListeners();
  }

  void searchFollowedOrganizations(String query) {
    _currentFollowedOrgSearchQuery = query.toLowerCase();
    if (query.isEmpty) {
      _filteredFollowedOrganizations = List.from(_followedOrganizations);
    } else {
      _filteredFollowedOrganizations = _followedOrganizations.where((org) {
        final orgName = org.organizationName?.toLowerCase() ?? '';
        final city = org.city?.toLowerCase() ?? '';
        return orgName.contains(_currentFollowedOrgSearchQuery) ||
            city.contains(_currentFollowedOrgSearchQuery);
      }).toList();
    }
    notifyListeners();
  }

  Future<void> fetchAllActivities(String userId) async {
    _isActivitiesLoading = true;
    _activitiesError = null;
    notifyListeners();

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('activities')
          .orderBy('timestamp', descending: true)
          .get();

      _latestActivities = querySnapshot.docs
          .map((doc) => ActivityModel.fromMap(doc.data()))
          .toList();

      await _fetchRelatedDataForActivities();

    } catch (e) {
      _activitiesError = 'Помилка завантаження активностей: $e';
    } finally {
      _isActivitiesLoading = false;
      notifyListeners();
    }
  }

  Future<void> _fetchRelatedDataForActivities() async {
    final eventIds = <String>{};
    final projectIds = <String>{};
    final fundraisingIds = <String>{};

    for (var activity in _latestActivities) {
      switch (activity.type) {
        case ActivityType.eventParticipation:
        case ActivityType.eventOrganization:
          eventIds.add(activity.entityId);
          break;
        case ActivityType.projectParticipation:
        case ActivityType.projectOrganization:
          projectIds.add(activity.entityId);
          break;
        case ActivityType.fundraiserDonation:
        case ActivityType.fundraiserCreation:
          fundraisingIds.add(activity.entityId);
          break;
      }
    }

    final eventService = EventService();

    if (eventIds.isNotEmpty) {
      _eventsData = await eventService.getEventsByIds(eventIds.toList());
    }
    if (projectIds.isNotEmpty) {
      _projectsDataActivities = await _projectService.getProjectByIds(projectIds.toList());
    }
    if (fundraisingIds.isNotEmpty) {
      _fundraisingsData = await _fundraiserService.getFundraisingsByIds(fundraisingIds.toList());
    }
  }
  Future<BaseProfileModel?> fetchUser(String? userId) async {
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

  void _listenToActiveFundraisings(String organizationId) {
    _activeFundraisingsSubscription?.cancel();
    _activeFundraisingsSubscription = _fundraiserService
        .getOrganizationActiveFundraisingsStream(organizationId)
        .listen((fundraisings) {
          _activeFundraisings = fundraisings
            ..sort((a, b) {
              // Пріоритет для термінових зборів
              final isAUrgent = a.isUrgent ?? false;
              final isBUrgent = b.isUrgent ?? false;

              if (isAUrgent && !isBUrgent) {
                return -1;
              }
              if (!isAUrgent && isBUrgent) {
                return 1;
              }

              // Сортуємо за часом (новіші перші)
              final aTimestamp = a.timestamp ?? DateTime(1970);
              final bTimestamp = b.timestamp ?? DateTime(1970);

              return bTimestamp.compareTo(aTimestamp);
            });
          notifyListeners();
        });
  }
}
