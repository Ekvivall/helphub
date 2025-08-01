import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' hide ActivityType;
import 'package:helphub/core/services/activity_service.dart';
import 'package:helphub/core/services/category_service.dart';
import 'package:helphub/core/services/event_service.dart';
import 'package:helphub/core/services/friend_service.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/event_model.dart';

import '../../core/utils/constants.dart';
import '../../models/activity_model.dart';
import '../../models/organization_model.dart';
import '../../models/volunteer_model.dart';

class EventViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventService _eventService = EventService();
  final CategoryService _categoryService = CategoryService();
  final FriendService _friendService = FriendService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActivityService _activityService = ActivityService();

  StreamSubscription<List<EventModel>>? _eventsSubscription;
  List<EventModel> _allEvents = [];
  List<EventModel> _filteredEvents = [];
  bool _isLoading = true;
  String? _errorMessage;

  //Фільтри
  List<CategoryChipModel> _availableCategories = [];
  List<CategoryChipModel> _selectedCategories = [];
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  String _searchQuery = '';
  double? _searchRadius;
  GeoPoint? _userLocation;
  int? _minDurationMinutes;
  int? _maxDurationMinutes;

  EventModel? _currentEvent;
  StreamSubscription<EventModel>? _currentEventSubscription;
  bool _isJoiningLeaving =
      false; // Для індикатора завантаження кнопки Долучитися/Залишити
  List<BaseProfileModel?> _participatingFriends = [];

  List<EventModel> get filteredEvents => _filteredEvents;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  List<CategoryChipModel> get availableCategories => _availableCategories;

  List<CategoryChipModel> get selectedCategories => _selectedCategories;

  DateTime? get selectedStartDate => _selectedStartDate;

  DateTime? get selectedEndDate => _selectedEndDate;

  GeoPoint? _currentUserLocation;

  GeoPoint? get currentUserLocation => _currentUserLocation;

  double? get searchRadius => _searchRadius;

  int? get minDurationMinutes => _minDurationMinutes;

  int? get maxDurationMinutes => _maxDurationMinutes;

  EventModel? get currentEvent => _currentEvent;

  bool get isJoiningLeaving => _isJoiningLeaving;

  List<BaseProfileModel?> get participatingFriends => _participatingFriends;

  String? _currentAuthUserId; // UID поточного авторизованого користувача
  String? get currentAuthUserId => _currentAuthUserId;
  BaseProfileModel? _user;
  BaseProfileModel? _organizer;

  BaseProfileModel? get user => _user;

  BaseProfileModel? get organizer => _organizer;

  EventViewModel() {
    _auth.authStateChanges().listen((user) async {
      _currentAuthUserId = user?.uid;
      _user = await fetchUserProfile(currentAuthUserId);
      _listenToEvents();
    });
    _loadAvailableCategories();
    _getCurrentUserLocation();
  }

  Future<BaseProfileModel?> fetchUserProfile(String? userId) async {
    try {
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

  Future<void> _loadAvailableCategories() async {
    try {
      _availableCategories = await _categoryService.fetchCategories();
      notifyListeners();
    } catch (e) {
      print('Error loading available categories: $e');
    }
  }

  void _listenToEvents() {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    _eventsSubscription?.cancel();
    _eventsSubscription = _eventService.getEventsStream().listen(
      (events) {
        _allEvents = events.where((event) {
          final bool hasNotStarted = event.date.isAfter(DateTime.now());
          final bool hasAvailableSpots =
              event.participantIds.length < event.maxParticipants;
          return hasNotStarted &&
              hasAvailableSpots &&
              (_user!.city == null || event.city == _user!.city);
        }).toList();
        _isLoading = false;
        _applyFilters();
      },
      onError: (error) {
        _errorMessage = 'Помилка завантаження подій: $error';
        _isLoading = false;
        _allEvents = [];
        _filteredEvents = [];
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
    int? minMinutes,
    int? maxMinutes,
    double? radius,
    DateTime? startDate,
    DateTime? endDate,
  ) {
    _selectedCategories = categories;
    _minDurationMinutes = minMinutes;
    _maxDurationMinutes = maxMinutes;
    _searchRadius = radius;
    _selectedStartDate = startDate;
    _selectedEndDate = endDate;
    _applyFilters();
  }

  void clearFilters() {
    _selectedCategories = [];
    _selectedStartDate = null;
    _selectedEndDate = null;
    _searchQuery = '';
    _searchRadius = null;
    _minDurationMinutes = null;
    _maxDurationMinutes = null;
    _applyFilters();
  }

  void _applyFilters() {
    List<EventModel> tempEvents = List.from(_allEvents);

    // Фільтрація за пошуковим запитом
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      tempEvents = tempEvents.where((event) {
        return event.name.toLowerCase().contains(queryLower) ||
            event.description.toLowerCase().contains(queryLower) ||
            event.locationText.toLowerCase().contains(queryLower);
      }).toList();
    }

    //Фільтрація за категоріями
    if (_selectedCategories.isNotEmpty) {
      tempEvents = tempEvents.where((event) {
        return event.categories.any(
          (eventCategory) => _selectedCategories.any(
            (selectedCategory) => selectedCategory.title == eventCategory.title,
          ),
        );
      }).toList();
    }

    // Фільтрація за датою
    if (_selectedStartDate != null) {
      tempEvents = tempEvents.where((event) {
        final eventDate = DateTime(
          event.date.year,
          event.date.month,
          event.date.day,
        );
        final startDate = DateTime(
          _selectedStartDate!.year,
          _selectedStartDate!.month,
          _selectedStartDate!.day,
        );
        final endDate = _selectedEndDate != null
            ? DateTime(
                _selectedEndDate!.year,
                _selectedEndDate!.month,
                _selectedEndDate!.day,
              )
            : startDate;
        return eventDate.isAtSameMomentAs(startDate) ||
            eventDate.isAfter(startDate) &&
                eventDate.isBefore(endDate.add(const Duration(days: 1)));
      }).toList();
    }
    // Фільтрація за локацією (радіус)
    if (_userLocation != null && _searchRadius != null && _searchRadius! > 0) {
      tempEvents = tempEvents.where((event) {
        if (event.locationGeoPoint == null) return false;
        final double distanceInMeters = Geolocator.distanceBetween(
          _currentUserLocation!.latitude,
          _currentUserLocation!.longitude,
          event.locationGeoPoint!.latitude,
          event.locationGeoPoint!.longitude,
        );
        final double searchRadiusMeters = _searchRadius! * 1000;
        return distanceInMeters <= searchRadiusMeters;
      }).toList();
    }
    // Фільтрація за тривалістю
    if (_minDurationMinutes != null || _maxDurationMinutes != null) {
      tempEvents = tempEvents.where((event) {
        final int? eventDurationInMinutes =
            Constants.parseDurationStringToMinutes(event.duration);
        if (eventDurationInMinutes == null) return false;
        bool matchesMin =
            _minDurationMinutes == null ||
            eventDurationInMinutes >= _minDurationMinutes!;
        bool matchesMax =
            _maxDurationMinutes == null ||
            eventDurationInMinutes <= _maxDurationMinutes!;
        return matchesMin && matchesMax;
      }).toList();
    }
    _filteredEvents = tempEvents;
    notifyListeners();
  }

  Future<void> loadEventDetails(String eventId) async {
    _isLoading = true;
    _errorMessage = null;
    _organizer = null;
    _participatingFriends = [];
    notifyListeners();
    await _currentEventSubscription?.cancel();
    try {
      _currentEventSubscription = _eventService
          .getEventStream(eventId)
          .listen(
            (event) async {
              _currentEvent = event;
              _organizer = await fetchUserProfile(event.organizerId);
              if (currentAuthUserId != null) {
                _participatingFriends = await _fetchParticipatingFriends(
                  event.participantIds,
                  currentAuthUserId,
                );
              }
              _isLoading = false;
              notifyListeners();
            },
            onError: (error) {
              _errorMessage = 'Помилка завантаження події: $error';
              _isLoading = false;
              notifyListeners();
            },
          );
    } catch (e) {
      _errorMessage = 'Не вдалося завантажити деталі події.';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearEventDetails() {
    _currentEventSubscription?.cancel();
    _currentEventSubscription = null;
    _currentEvent = null;
    _isJoiningLeaving = false;
  }

  Future<String?> joinEvent(EventModel event, String userId) async {
    _isJoiningLeaving = true;
    notifyListeners();
    try {
      await _eventService.addParticipant(event.id!, userId);
      final activity = ActivityModel(
        type: ActivityType.eventParticipation,
        entityId: event.id!,
        title: event.name,
        description: event.description,
        timestamp: DateTime.now(),
      );
      await _activityService.logActivity(userId, activity);
      return null;
    } catch (e) {
      _errorMessage = 'Не вдалося долучитися до події.';
      return _errorMessage;
    } finally {
      _isJoiningLeaving = false;
      notifyListeners();
    }
  }

  Future<String?> leaveEvent(String eventId, String userId) async {
    _isJoiningLeaving = true;
    notifyListeners();
    try {
      await _eventService.removeParticipant(eventId, userId);
      await _activityService.deleteActivity(
        userId,
        ActivityType.eventParticipation,
        eventId,
      );
      return null;
    } catch (e) {
      _errorMessage = 'Не вдалося залишити подію.';
      return _errorMessage;
    } finally {
      _isJoiningLeaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getCurrentUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission == await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
    Position position = await Geolocator.getCurrentPosition();
    _currentUserLocation = GeoPoint(position.latitude, position.longitude);
    notifyListeners();
  }

  Future<List<BaseProfileModel?>> _fetchParticipatingFriends(
    List<String> participantIds,
    String? currentAuthUserId,
  ) async {
    final List<String> userFriendUids = await _friendService.getFriendsUids();
    final List<String> friendsInEventUids = participantIds.where((participant) {
      return userFriendUids.contains(participant);
    }).toList();
    List<BaseProfileModel?> temp = [];
    for (var uid in friendsInEventUids) {
      temp.add(await fetchUserProfile(uid));
    }
    return temp;
  }
}
