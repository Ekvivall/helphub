import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/data/models/base_profile_model.dart';

import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class AuthViewModel extends ChangeNotifier {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool _isLoading = false;
  bool _showValidationErrors = false;

  bool get isLoading => _isLoading;

  bool get showValidationErrors => _showValidationErrors;

  AuthViewModel() {
    emailController = TextEditingController();
    passwordController = TextEditingController();
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
          'lastSignInAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      Constants.showSuccessMessage(context, 'Успішний вхід!');
      Navigator.of(context).pushReplacementNamed(AppRoutes.eventListScreen);
    } on FirebaseAuthException catch (e) {
      String errorMessage =
          'Помилка входу: ${e.message ?? 'Невідома помилка автентифікації'}';
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

  void handleForgotPassword(BuildContext context) async {
    final String email = emailController.text.trim();
    _setLoading(true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      Constants.showSuccessMessage(
        context,
        'Лист для скидання пароля надіслано на вашу електронну пошту. Перевірте вхідні та папку "Спам".',
      );
      emailController.clear();
    } on FirebaseAuthException catch (e) {
      String errorMessage =
          'Не вдалося надіслати лист для скидання пароля: ${e.message ?? 'Невідома помилка'}';
      if (e.code == 'user-not-found') {
        errorMessage = 'Користувача з такою електронною поштою не знайдено.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Введено некоректний формат електронної пошти.';
      }
      Constants.showErrorMessage(context, errorMessage);
    } catch (e) {
      Constants.showErrorMessage(
        context,
        'Сталася невідома помилка: ${e.toString()}',
      );
    } finally {
      _setLoading(false);
    }
  }

  void handleRegister(BuildContext context) {
    Navigator.of(context).pushNamed(AppRoutes.registerTypeScreen);
  }

  void selectRole(BuildContext context, UserRole role) {
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
