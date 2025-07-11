import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/base_profile_model.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/organization_model.dart';
import 'package:helphub/models/volunteer_model.dart';

class ProfileViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  BaseProfileModel? _user; // Поточні дані користувача
  bool _isLoading = false;
  bool _isEditing = false;
  String? _selectedCity;
  List<CategoryChipModel> _selectedInterests = [];

  late TextEditingController fullNameController;
  late TextEditingController organizationNameController;
  late TextEditingController websiteController;
  late TextEditingController aboutMeController;
  late TextEditingController nicknameController;
  late TextEditingController phoneNumberController;
  late TextEditingController telegramLinkController;
  late TextEditingController instagramLinkController;

  BaseProfileModel? get user => _user;

  bool get isLoading => _isLoading;

  bool get isEditing => _isEditing;

  String? get selectedCity => _selectedCity;

  List<CategoryChipModel> get selectedInterests => _selectedInterests;

  final String? _viewingUserId; // ID користувача, який переглядається
  String? _currentAuthUserId; // UID поточного авторизованого користувача
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
    _auth.authStateChanges().listen((user) {
      _currentAuthUserId = user?.uid;
      if ((_viewingUserId != null || user != null) && _user == null) {
        fetchUserProfile();
      }
      if (_viewingUserId != null && _viewingUserId != user?.uid) {
        fetchUserProfile();
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
        if (roleString == UserRole.volunteer.name) {
          _user = VolunteerModel.fromMap(doc.data()!);
        } else {
          _user = OrganizationModel.fromMap(doc.data()!);
        }
        if (uidToFetch == _currentAuthUserId) {
          _fillControllersFromUser();
        }
      } else {
        _user = null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserData() async {
    if (_user == null) return;
    _setLoading(true);
    try {
      if (_user is VolunteerModel) {
        final updatedUser = (_user as VolunteerModel).copyWith(
          fullName: fullNameController.text.trim().isNotEmpty
              ? fullNameController.text.trim()
              : null,
          city: _selectedCity,
          aboutMe: aboutMeController.text.trim().isNotEmpty
              ? aboutMeController.text.trim()
              : null,
          displayName: nicknameController.text.trim().isNotEmpty
              ? nicknameController.text.trim()
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
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(updatedUser.toMap(), SetOptions(merge: true));
        _user = updatedUser;
      } else if (_user is OrganizationModel) {
        final updatedOrganization = (_user as OrganizationModel).copyWith(
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
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .set(updatedOrganization.toMap(), SetOptions(merge: true));
        _user = updatedOrganization;
      }
      _isEditing = false;
    } catch (e) {
      print('Error updating user data: $e');
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
      organizationNameController.text = '';
      websiteController.text = '';
      aboutMeController.text = '';
      _selectedCity = null;
    }
    notifyListeners();
  }

  void toggleInterest(CategoryChipModel interest) {
    final existingInterestIndex = _selectedInterests.indexWhere((element) => element.title == interest.title);
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
}
