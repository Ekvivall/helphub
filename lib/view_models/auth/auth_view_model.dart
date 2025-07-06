import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/user_model.dart';
import 'package:helphub/theme/theme_helper.dart';

import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class AuthViewModel extends ChangeNotifier {
  late TextEditingController emailController;
  late TextEditingController passwordController;
  bool _isLoading = false;
  bool _showValidationErrors = false;

  UserModel? _currentUser;

  bool get isLoading => _isLoading;

  bool get showValidationErrors => _showValidationErrors;

  UserModel? get currentUser => _currentUser;

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
        _currentUser = await fetchUserProfile(user.uid);
        if (_currentUser == null) {
          _currentUser = UserModel(
            uid: user.uid,
            email: user.email,
            role: UserRole.volunteer,
            lastSignInAt: DateTime.now(),
            createdAt: user.metadata.creationTime,
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(_currentUser!.toMap(), SetOptions(merge: true));
        } else {
          _currentUser = _currentUser!.copyWith(lastSignInAt: DateTime.now());
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'lastSignInAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        }
        Constants.showSuccessMessage(context, 'Успішний вхід!');
        Navigator.of(context).pushNamed(AppRoutes.eventMapScreen);
      } else {
        Constants.showErrorMessage(
          context,
          'Помилка входу: Користувача не знайдено',
        );
      }
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

  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!);
    }
    return null;
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
