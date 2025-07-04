import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/authentication_model.dart';
import 'package:helphub/models/user_model.dart';
import 'package:helphub/theme/theme_helper.dart';

import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class AuthViewModel extends ChangeNotifier {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  AuthenticationModel _authenticationModel = AuthenticationModel();
  bool _isLoading = false;
  bool _showValidationErrors = false;

  AuthenticationModel get authenticationModel => _authenticationModel;

  bool get isLoading => _isLoading;

  bool get showValidationErrors => _showValidationErrors;

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

  Future<void> handleLogin(
    BuildContext context,
    GlobalKey<FormState> formKey,
  ) async {
    FocusScope.of(context).unfocus();
    if (!formKey.currentState!.validate()) {
      _showValidationErrors = true;
      notifyListeners();
      return;
    }
    _authenticationModel.email = emailController.text;
    _authenticationModel.password = passwordController.text;
    _showValidationErrors = false;
    _setLoading(true);
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'lastSignInAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        Constants.showSuccessMessage(context, 'Успішний вхід!');
        Navigator.of(context).pushNamed(AppRoutes.eventMapScreen);
      } else {
        Constants.showErrorMessage(
          context,
          'Помилка входу: Користувача не знайдено',
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Помилка входу: ${e.message ?? 'Невідома помилка автентифікації'}';
      if (e.code == 'user-not-found' ||
          e.code == 'wrong-password' ||
          e.code == 'invalid-credential') {
        errorMessage = 'Неправильна електронна пошта або пароль.';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Ваш обліковий запис вимкнено.';
      }
      Constants.showErrorMessage(context, errorMessage); //
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка входу: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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
      Navigator.of(
        context,
      ).pushNamed(AppRoutes.registerOrganizationStep1Screen);
    }
  }

  void handleBackToLogin(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.loginScreen);
  }
}
