import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helphub/core/utils/image_constant.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/volunteer_model.dart';

import '../../routes/app_router.dart';
import '../../theme/theme_helper.dart';

class Constants {
  static List<String> cities = [
    'Вінниця',
    'Дніпро',
    'Житомир',
    'Запоріжжя',
    'Івано-Франківськ',
    'Київ',
    'Кривий Ріг',
    'Луцьк',
    'Львів',
    'Маріуполь',
    'Миколаїв',
    'Одеса',
    'Полтава',
    'Рівне',
    'Суми',
    'Тернопіль',
    'Ужгород',
    'Харків',
    'Херсон',
    'Хмельницький',
    'Черкаси',
    'Чернігів',
    'Чернівці',
  ];

  static void showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appThemeColors.errorRed,
      ),
    );
  }

  static void showSuccessMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: appThemeColors.successGreen,
      ),
    );
  }

  static Future<void> handleGoogleSignIn(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Вхід через Google...'),
          backgroundColor: appThemeColors.blueAccent,
        ),
      );
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        Constants.showErrorMessage(context, 'Вхід через Google скасовано.');
      }
      final GoogleSignInAuthentication? googleAuth =
          await googleUser?.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );
      // Вхід до Firebase за допомогою облікових даних Google
      final UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);
      User? user = userCredential.user;
      if (user != null) {
        VolunteerModel googleUser = VolunteerModel(
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
          photoUrl: user.photoURL,
          lastSignInAt: DateTime.now(),
          createdAt: userCredential.additionalUserInfo?.isNewUser == true
              ? DateTime.now()
              : null,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(googleUser.toMap(), SetOptions(merge: true));
        Constants.showSuccessMessage(
          context,
          'Вхід через Google успішно завершено!',
        );
        Navigator.of(context).pushNamed(AppRoutes.eventMapScreen);
      } else {
        Constants.showErrorMessage(
          context,
          'Не вдалося увійти через Google. Користувача не знайдено.',
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          errorMessage =
              'Обліковий запис вже існує з іншими обліковими даними. Спробуйте увійти іншим способом.';
          break;
        case 'invalid-credential':
          errorMessage =
              'Невірні облікові дані Google. Будь ласка, спробуйте ще раз.';
          break;
        case 'user-disabled':
          errorMessage =
              'Ваш обліковий запис вимкнено. Зв\'яжіться з підтримкою.';
          break;
        case 'operation-not-allowed':
          errorMessage =
              'Вхід за допомогою Google не ввімкнено у Firebase для цього проекту.';
          break;
        case 'network-request-failed':
          errorMessage =
              'Помилка мережі. Перевірте ваше підключення до Інтернету.';
          break;
        default:
          errorMessage = 'Невідома помилка входу через Google: ${e.message}';
          break;
      }
      Constants.showErrorMessage(context, errorMessage);
    } catch (e) {
      Constants.showErrorMessage(
        context,
        'Помилка входу через Google: ${e.toString()}',
      );
    }
  }

  // Можливі сфери інтересів
  static final List<CategoryChipModel> availableInterests = [
    CategoryChipModel(
      title: 'Діти',
      imagePath: ImageConstant.categoryChildIcon,
      backgroundColor: Colors.orange.shade200,
      textColor: appThemeColors.primaryBlack,
    ),
    CategoryChipModel(
      title: 'Екологія',
      imagePath: ImageConstant.categoryEcologyIcon,
      backgroundColor: Colors.green.shade200,
      textColor: appThemeColors.primaryBlack,
    ),
    CategoryChipModel(
      title: 'ЗСУ',
      imagePath: ImageConstant.categoryAfuIcon,
      backgroundColor: Colors.blue.shade200,
      textColor: appThemeColors.primaryBlack,
    ),
    CategoryChipModel(
      title: 'Медицина',
      imagePath: ImageConstant.categoryMedicalIcon,
      backgroundColor: Colors.red.shade200,
      textColor: appThemeColors.primaryBlack,
    ),
    CategoryChipModel(
      title: 'Освіта',
      imagePath: ImageConstant.categoryEducationIcon,
      backgroundColor: Colors.purple.shade200,
      textColor: appThemeColors.primaryBlack,
    ),
    CategoryChipModel(
      title: 'Тварини',
      imagePath: ImageConstant.categoryAnimalIcon,
      backgroundColor: Colors.brown.shade200,
      textColor: appThemeColors.primaryBlack,
    ),
  ];
}
