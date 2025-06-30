import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';

class OrganizationRegisterViewModel extends ChangeNotifier {
  final TextEditingController organizationNameController =
      TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  String? _selectedCity;

  String? get selectedCity => _selectedCity;

  final List<String> cities = [
    'Київ',
    'Харків',
    'Одеса',
    'Дніпро',
    'Запоріжжя',
    'Львів',
    'Кривий Ріг',
    'Миколаїв',
    'Маріуполь',
    'Вінниця',
    'Херсон',
    'Полтава',
    'Чернігів',
    'Черкаси',
    'Житомир',
    'Суми',
    'Хмельницький',
    'Чернівці',
    'Івано-Франківськ',
    'Тернопіль',
    'Луцьк',
    'Рівне',
    'Ужгород',
  ];
  List<PlatformFile> _selectedDocuments = [];

  List<PlatformFile> get selectedDocuments => _selectedDocuments;
  bool _isAgreementAccepted = false;

  bool get isAgreementAccepted => _isAgreementAccepted;
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  @override
  void dispose() {
    organizationNameController.dispose();
    emailController.dispose();
    websiteController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void updateOrganizationName(String value) {
    notifyListeners();
  }

  void updateEmail(String value) {
    notifyListeners();
  }

  void updateWebsite(String value) {
    notifyListeners();
  }

  void updateCity(String newValue) {
    _selectedCity = newValue;
    notifyListeners();
  }

  Future<void> pickDocument() async {
    _isLoading = true;
    notifyListeners();
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'xlsx'],
        allowMultiple: true
      );
      if (result != null && result.files.isNotEmpty) {
        _selectedDocuments = result.files;
      } else {
        _selectedDocuments = [];
      }
    } catch (e) {
      _selectedDocuments = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updatePassword(String value) {
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    notifyListeners();
  }

  void updateAgreement(bool value) {
    _isAgreementAccepted = value;
    notifyListeners();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get isFormValidStep1 {
    return organizationNameController.text.isNotEmpty &&
        _isValidEmail(emailController.text) &&
        _selectedCity != null;
  }

  bool get isFormValidStep2 {
    return _selectedDocuments.isNotEmpty &&
        passwordController.text.length >= 6 &&
        passwordController.text == confirmPasswordController.text &&
        _isAgreementAccepted;
  }

  Future<void> handleRegistrationStep1(BuildContext context) async {
    if (!isFormValidStep1) {
      return;
    }
    Navigator.of(context).pushNamed(AppRoutes.registerOrganizationStep2Screen);
  }

  Future<void> handleRegistrationStep2(BuildContext context) async {
    if (!isFormValidStep2) {
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      Navigator.of(context).pushReplacementNamed(AppRoutes.eventMapScreen);
    } catch (e) {
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
