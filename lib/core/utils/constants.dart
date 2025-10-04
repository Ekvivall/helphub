import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/notification_model.dart';
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
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;

        if (isNewUser) {
          VolunteerModel newUserProfile = VolunteerModel(
            uid: user.uid,
            email: user.email,
            displayName: user.displayName,
            photoUrl: user.photoURL,
            lastSignInAt: DateTime.now(),
            createdAt: DateTime.now(),
            levelProgress: 1,
            projectsCount: 0,
            eventsCount: 0,
          );
          await userDocRef.set(newUserProfile.toMap());
        } else {
          await userDocRef.update({
            'lastSignInAt': Timestamp.now(),
            'photoUrl': user.photoURL,
            'displayName': user.displayName,
          });
        }

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

  static String calculateDistance(
    GeoPoint? eventLocation,
    GeoPoint? userLocation,
  ) {
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

      final time = TimeOfDay(hour: hour, minute: minute);

      if (time.hour != hour || time.minute != minute) {
        return null;
      }

      return time;
    } catch (e) {
      return null;
    }
  }

  static int? calculateDaysRemaining(DateTime? endDate) {
    if (endDate == null) return null;
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inDays;
  }

  static String formatDaysRemaining(int days) {
    if (days < 0) return 'Завершено';
    if (days == 0) return 'Останній день';
    if (days == 1) return '1 день';
    if (days < 5) return '$days дні';
    return '$days днів';
  }

  static String formatAmount(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]} ',
        );
  }

  static String getFileNameFromUrl(String url) {
    return url.split('/').last.split('?').first;
  }

  static IconData getDocumentIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  static void copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    Constants.showSuccessMessage(context, 'Скопійовано до буфера обміну');
  }

  static void openDocument(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Constants.showErrorMessage(context, 'Не вдалося відкрити документ');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка при відкритті документа');
    }
  }

  static void openBankLink(BuildContext context, String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Constants.showErrorMessage(context, 'Не вдалося відкрити посилання');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Некоректне посилання');
    }
  }

  static void pickImageFromCamera(
    ImagePicker imagePicker,
    BuildContext context,
    Function(File file) function,
    double maxWidth,
    double maxHeight,
  ) async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: 80,
      );

      if (image != null) {
        await function(File(image.path));
      }
    } catch (e) {
      showErrorMessage(context, 'Помилка при зйомці фото: $e');
    }
  }

  static void pickImageFromGallery(
    ImagePicker imagePicker,
    BuildContext context,
    Function(File file) function,
    double maxWidth,
    double maxHeight,
  ) async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: 80,
      );

      if (image != null) {
        await function(File(image.path));
      }
    } catch (e) {
      showErrorMessage(context, 'Помилка при виборі фото: $e');
    }
  }

  static

  void showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: 200,
                        height: 200,
                        color: appThemeColors.backgroundLightGrey,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: appThemeColors.blueAccent,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        color: appThemeColors.errorRed.withAlpha(77),
                        child: Icon(
                          Icons.broken_image,
                          color: appThemeColors.errorRed,
                          size: 60,
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: appThemeColors.primaryBlack.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.close,
                      color: appThemeColors.primaryWhite,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const Map<NotificationCategory, List<NotificationType>> notificationGroups = {
    NotificationCategory.messagesAndChat: [
      NotificationType.chat,
    ],
    NotificationCategory.projectActivities: [
      NotificationType.projectApplication,
      NotificationType.projectApplicationEdit,
      NotificationType.taskAssigned,
      NotificationType.taskCompleted,
      NotificationType.taskConfirmed,
      NotificationType.projectDeadline,
    ],
    NotificationCategory.fundraisingActivities: [
      NotificationType.fundraisingApplication,
      NotificationType.fundraisingApplicationEdit,
      NotificationType.fundraisingDonation,
      NotificationType.newFundraising,
      NotificationType.fundraisingCompleted,
      NotificationType.raffleWinner,
    ],
    NotificationCategory.eventActivities: [
      NotificationType.eventUpdate,
      NotificationType.eventReminder,
    ],
    NotificationCategory.social: [
      NotificationType.friendRequest,
      NotificationType.friendRequestEdit,
    ],
    NotificationCategory.accountAndSystem: [
      NotificationType.achievement,
      NotificationType.adminNotification,
      NotificationType.systemMaintenance,
      NotificationType.appUpdate,
      NotificationType.general,
      NotificationType.reportCreated,
    ],
  };

}
