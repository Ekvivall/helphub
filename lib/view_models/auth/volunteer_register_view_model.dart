import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../theme/theme_helper.dart';

class VolunteerRegisterViewModel extends ChangeNotifier {
  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  bool _isLoading = false;
  bool _isAgreementAccepted = false;
  String _fullName = '';
  String _email = '';
  String _password = '';
  String _confirmPassword = '';
  String? _selectedCity;

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

  bool get isLoading => _isLoading;

  bool get isAgreementAccepted => _isAgreementAccepted;

  String get fullName => _fullName;

  String get email => _email;

  String get password => _password;

  String get confirmPassword => _confirmPassword;

  String? get selectedCity => _selectedCity;

  VolunteerRegisterViewModel() {
    fullNameController = TextEditingController();
    emailController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool get isFormValid {
    return _fullName.isNotEmpty &&
        _email.isNotEmpty &&
        _password.isNotEmpty &&
        _confirmPassword.isNotEmpty &&
        _selectedCity != null &&
        _isAgreementAccepted &&
        _password == _confirmPassword &&
        _isValidEmail(_email) &&
        _password.length >= 6;
  }

  void updateFullName(String value) {
    _fullName = value;
    notifyListeners();
  }

  void updateEmail(String value) {
    _email = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    notifyListeners();
  }

  void updateConfirmPassword(String value) {
    _confirmPassword = value;
    notifyListeners();
  }

  void updateCity(String newValue) {
    _selectedCity = newValue;
    notifyListeners();
  }

  void updateAgreement(bool value) {
    _isAgreementAccepted = value;
    notifyListeners();
  }

  Future<void> handleRegistration(BuildContext context) async {
    if (!isFormValid) {
      _showErrorMessage(
        context,
        'Перевірте правильність заповнення всіх полів',
      );
      return;
    }

    if (_password != _confirmPassword) {
      _showErrorMessage(context, 'Паролі не співпадають');
      return;
    }
    _isLoading = true;
    notifyListeners();
    try {
      await Future.delayed(const Duration(seconds: 2));
      _showSuccessMessage(context, 'Реєстрацію успішно завершено!');
      Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
    } catch (e) {
      _showErrorMessage(context, 'Помилка реєстрації: ${e.toString()}');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appThemeColors.errorRed,
      ),
    );
  }

  void _showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appThemeColors.successGreen,
      ),
    );
  }

  void handleGoogleSignIn(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Вхід через Google...'),
        backgroundColor: appThemeColors.blueAccent,
      ),
    );
  }

}
