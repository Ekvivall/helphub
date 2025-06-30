import 'package:flutter/material.dart';
import 'package:helphub/models/authentication_model.dart';
import 'package:helphub/models/user_model.dart';
import 'package:helphub/theme/theme_helper.dart';

import '../../routes/app_router.dart';

class AuthViewModel extends ChangeNotifier {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  AuthenticationModel _authenticationModel = AuthenticationModel();
  bool _isLoading = false;
  String _email = '';
  String _password = '';

  AuthenticationModel get authenticationModel => _authenticationModel;

  bool get isLoading => _isLoading;

  String get email => _email;

  String get password => _password;

  AuthViewModel() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
    _authenticationModel = AuthenticationModel();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void updateEmail(String value) {
    _email = value;
    _authenticationModel.email = value;
    notifyListeners();
  }

  void updatePassword(String value) {
    _password = value;
    _authenticationModel.password = value;
    notifyListeners();
  }

  String? validateEmail(String email) {
    if (email.isEmpty) return 'Електронна пошта не може бути пустою\n';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'Введіть коректну електронну пошту';
    }
    return null;
  }

  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Пароль не може бути пустим';
    } else if (password.length < 6)
      return 'Пароль повинен містити мінімум 6 символів';
    return null;
  }

  String get isFormValid {
    String result = '';
    String? validEmail = validateEmail(_email);
    String? validPassword = validatePassword(_password);
    if (validEmail != null) {
      result += validEmail;
    }
    if (validPassword != null) {
      result += validPassword;
    }
    return result;
  }

  Future<void> handleLogin(BuildContext context) async {
    FocusScope.of(context).unfocus();
    String isValid = isFormValid;
    if (isValid != '') {
      _showErrorMessage(context, isValid);
      return;
    }
    _setLoading(true);
    try {
      await Future.delayed(Duration(seconds: 1));
      _showSuccessMessage(context, 'Успішний вхід!');
    } catch (e) {
      _showErrorMessage(context, 'Помилка входу: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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

  void handleForgotPassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Відновлення пароля...'),
        backgroundColor: appThemeColors.blueAccent,
      ),
    );
  }

  void handleRegister(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.registerTypeScreen);
  }

  void selectRole(BuildContext context, UserRole role) {
    _authenticationModel.role = role;
    notifyListeners();
    if (role == UserRole.volunteer) {
      Navigator.of(context).pushNamed(AppRoutes.registerVolunteerScreen);
    } else {
      Navigator.of(context).pushNamed(AppRoutes.registerOrganizationStep1Screen);
    }
  }

  void handleBackToLogin(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.loginScreen);
  }
}
