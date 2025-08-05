import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helphub/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:uuid/uuid.dart';

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
        Navigator.of(context).pushReplacementNamed(AppRoutes.eventListScreen);
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
          title: Text(title, style: TextStyleHelper.instance.title16Bold),
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

  static String formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
  static String formatTime(TimeOfDay time) {
    return '${time.hour}:${time.minute}';
  }

  static int? parseDurationStringToMinutes(String durationString) {
    durationString = durationString.toLowerCase();
    int totalMinutes = 0;
    bool parsed = false;
    // Регулярний вираз для пошуку чисел і одиниць вимірювання (години, хвилини)
    final RegExp regExp = RegExp(
      r'(\d+)\s*(годин|година|години|год|хвилин|хвилина|хвилини|хв)',
    );
    final matches = regExp.allMatches(durationString);

    for (var match in matches) {
      final int value = int.tryParse(match.group(1)!) ?? 0;
      final String unit = match.group(2)!;

      if (unit.startsWith('годин') ||
          unit.startsWith('година') ||
          unit.startsWith('години') ||
          unit.startsWith('год')) {
        totalMinutes += value * 60;
        parsed = true;
      } else if (unit.startsWith('хвилин') ||
          unit.startsWith('хвилина') ||
          unit.startsWith('хвилини') ||
          unit.startsWith('хв')) {
        totalMinutes += value;
        parsed = true;
      }
    }

    if (parsed) {
      return totalMinutes;
    }
    return null;
  }


  static String calculateDistance(GeoPoint? eventLocation, GeoPoint? userLocation) {
    if (eventLocation == null || userLocation == null) {
      return '';
    }
    double distanceInMeters = Geolocator.distanceBetween(
      userLocation.latitude,
      userLocation.longitude,
      eventLocation.latitude,
      eventLocation.longitude,
    );
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} м';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} км';
    }
  }


  static DateTime? parseDate(String dateString) {
    if (dateString.length != 10) return null;

    try {
      final parts = dateString.split('.');
      if (parts.length != 3) return null;

      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final date = DateTime(year, month, day);

      if (date.day != day || date.month != month || date.year != year) {
        return null;
      }

      return date;
    } catch (e) {
      return null;
    }
  }
  static TimeOfDay? parseTime(String timeString) {
    if (timeString.length != 5) return null;

    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      final time = TimeOfDay(hour: hour, minute:minute);

      if (time.hour != hour || time.minute != minute) {
        return null;
      }

      return time;
    } catch (e) {
      return null;
    }
  }
}
