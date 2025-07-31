import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:helphub/core/services/category_service.dart';
import 'package:helphub/core/services/event_service.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/event_model.dart';

import '../../core/utils/constants.dart';
import '../../models/organization_model.dart';
import '../../models/volunteer_model.dart';

class EventViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EventService _eventService = EventService();
  final CategoryService _categoryService = CategoryService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
  String? _currentAuthUserId; // UID поточного авторизованого користувача
  String? get currentAuthUserId => _currentAuthUserId;
  BaseProfileModel? _user;

  BaseProfileModel? get user => _user;

  EventViewModel() {
    _auth.authStateChanges().listen((user) {
      _currentAuthUserId = user?.uid;
      fetchUserProfile();
    });
    _loadAvailableCategories();
    _listenToEvents();
    _getCurrentUserLocation();
  }

  Future<void> fetchUserProfile() async {
    _isLoading = true;
    notifyListeners();
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentAuthUserId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        final roleString = data?['role'] as String?;
        if (roleString == UserRole.volunteer.name) {
          _user = VolunteerModel.fromMap(doc.data()!);
        } else {
          _user = OrganizationModel.fromMap(doc.data()!);
        }
      } else {
        _user = null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
        _allEvents = events;
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
        final int? eventDurationInMinutes = Constants.parseDurationStringToMinutes(
          event.duration,
        );
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
}
