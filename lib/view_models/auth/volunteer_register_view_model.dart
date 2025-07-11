import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/models/volunteer_model.dart';

import '../../core/utils/constants.dart';
import '../../routes/app_router.dart';

class VolunteerRegisterViewModel extends ChangeNotifier {
  late TextEditingController fullNameController;
  late TextEditingController emailController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;
  bool _isLoading = false;
  bool _isAgreementAccepted = false;
  String? _selectedCity;

  bool get isLoading => _isLoading;

  bool get isAgreementAccepted => _isAgreementAccepted;

  String? get selectedCity => _selectedCity;

  bool _showValidationErrors = false;

  bool get showValidationErrors => _showValidationErrors;

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

  void updateCity(String newValue) {
    _selectedCity = newValue;
    notifyListeners();
  }

  void updateAgreement(bool value) {
    _isAgreementAccepted = value;
    notifyListeners();
  }

  Future<void> handleRegistration(
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
    _isLoading = true;
    notifyListeners();
    try {
      // Створення користувача в FirebaseAuth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
      User? user = userCredential.user;
      if (user != null) {
        VolunteerModel newUser = VolunteerModel(
          uid: user.uid,
          email: emailController.text.trim(),
          fullName: fullNameController.text.trim(),
          city: _selectedCity,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap(), SetOptions(merge: true));
        Constants.showSuccessMessage(context, 'Реєстрацію успішно завершено!');
        Navigator.of(context).pushNamed(AppRoutes.eventMapScreen);
      } else {
        Constants.showErrorMessage(
          context,
          'Помилка реєстрації: Користувача не створено',
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Помилка реєстрації: ${e.message}';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'Ця електронна пошта вже використовується';
      }
      Constants.showErrorMessage(context, errorMessage);
    } catch (e) {
      Constants.showErrorMessage(
        context,
        'Помилка реєстрації: ${e.toString()}',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
