import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helphub/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:uuid/uuid.dart';

import '../../models/activity_model.dart';
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

  static String generateUniqueDisplayName(String email) {
    String baseName = email.split('@')[0];
    if (baseName.length > 15) {
      baseName = baseName.substring(0, 15);
    }
    var uuid = const Uuid();
    String uniqueId = uuid.v4().substring(0, 6);
    return '${baseName}_$uniqueId';
  }

  static void showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    String actionTitle,
    ProfileViewModel viewModel,
    String userId,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyleHelper.instance.title16ExtraBold),
          content: Text(
            content,
            style: TextStyleHelper.instance.title14Regular,
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Скасувати',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.errorRed,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                viewModel.unfriendViewingUser(userId);
              },
              child: Text(
                'Видалити',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<void> logActivity(String uid, ActivityModel activity) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('activities')
          .doc(activity.id)
          .set(activity.toMap());
    } catch (e) {
      print('Error logging activity: $e');
    }
  }
}
