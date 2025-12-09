import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:helphub/core/utils/constants.dart';
import 'package:helphub/data/models/support_ticket_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/settings/settings_view_model.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/models/admin_model.dart';
import '../../data/models/base_profile_model.dart';
import '../../data/models/organization_model.dart';
import '../../routes/app_router.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/notifications/notifications_settings.dart';
import '../../widgets/settings/settings_item.dart';
import '../../widgets/settings/settings_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.user == null) return SizedBox.shrink();
        final BaseProfileModel user = viewModel.user!;
        return Scaffold(
          backgroundColor: appThemeColors.blueAccent,
          appBar: AppBar(
            backgroundColor: appThemeColors.appBarBg,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                size: 40,
                color: appThemeColors.primaryWhite,
              ),
            ),
            title: Text(
              'Налаштування',
              style: TextStyleHelper.instance.headline24SemiBold.copyWith(
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ),
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(0.9, -0.4),
                end: const Alignment(-0.9, 0.4),
                colors: [appThemeColors.blueAccent, appThemeColors.cyanAccent],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User profile section
                  _buildUserProfileSection(user),
                  const SizedBox(height: 24),

                  //Notification settings section
                  buildSection(
                    'Сповіщення',
                    Icons.notifications_outlined,
                    appThemeColors.lightGreenColor,
                    [
                      buildSettingsItem(
                        'Керувати сповіщеннями',
                        'Налаштувати сповіщення за категоріями',
                        Icons.tune,
                        () => showNotificationsSettings(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  //Support and help section
                  buildSection(
                    'Підтримка та допомога',
                    Icons.help_outline,
                    appThemeColors.blueMixedColor,
                    [
                      buildSettingsItem(
                        'Центр підтримки',
                        'Зв\'яжіться з нами',
                        Icons.support_agent,
                        () => _openSupport(context),
                      ),
                      buildSettingsItem(
                        'Історія звернень',
                        'Переглянути мої запити та відповіді',
                        Icons.history,
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.userSupportHistoryScreen,
                        ),
                      ),
                      buildSettingsItem(
                        'Часто задавані питання',
                        'Відповіді на популярні питання',
                        Icons.quiz_outlined,
                        () => Navigator.pushNamed(context, AppRoutes.faqScreen),
                      ),
                      buildSettingsItem(
                        'Зворотний зв\'язок',
                        'Написати розробникові',
                        Icons.feed_outlined,
                        () => _showFeedbackDialog(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Account section
                  buildSection(
                    'Акаунт',
                    Icons.account_circle_outlined,
                    appThemeColors.blueAccent,
                    [
                      buildSettingsItem(
                        'Редагувати профіль',
                        'Змінити особисту інформацію',
                        Icons.edit_outlined,
                        () => Navigator.pushNamed(
                          context,
                          AppRoutes.editUserProfileScreen,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Privacy section
                  buildSection(
                    'Правова інформація',
                    Icons.gavel_outlined,
                    appThemeColors.purpleColor.withAlpha(187),
                    [
                      buildSettingsItem(
                        'Політика конфіденційності',
                        'Як ми захищаємо ваші дані',
                        Icons.privacy_tip_outlined,
                        () => _openPrivacyPolicy(),
                      ),
                      buildSettingsItem(
                        'Умови використання',
                        'Правила користування додатком',
                        Icons.description_outlined,
                        () => _openTermsOfService(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // About section
                  buildSection(
                    'Про додаток',
                    Icons.info_outline,
                    appThemeColors.goldColor,
                    [
                      buildSettingsItem(
                        'Версія додатку',
                        'v$_appVersion',
                        Icons.update,
                        null,
                      ),
                      buildSettingsItem(
                        'Поділитися додатком',
                        'Розказати друзям про HelpHub',
                        Icons.share_outlined,
                        () => _shareApp(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildSignOutButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserProfileSection(BaseProfileModel user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appThemeColors.primaryWhite.withAlpha(125)),
      ),
      child: Row(
        children: [
          UserAvatarWithFrame(
            size: 32,
            role: user.role,
            uid: user.uid,
            photoUrl: user.photoUrl,
            frame: user is VolunteerModel ? user.frame : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user is VolunteerModel
                      ? user.fullName ?? user.displayName ?? 'Волонтер'
                      : user is OrganizationModel
                      ? user.organizationName ?? 'Благодійний фонд'
                      : user is AdminModel
                      ? (user).fullName ?? 'Адмін'
                      : 'Користувач',
                  style: TextStyleHelper.instance.title16Bold.copyWith(
                    color: appThemeColors.primaryBlack,
                  ),
                ),
                const SizedBox(height: 4),
                if (user.email != null)
                  Text(
                    user.email ?? '',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    final viewModel = Provider.of<SettingsViewModel>(context, listen: false);
    final userProfile = viewModel.user;
    final authUser = FirebaseAuth.instance.currentUser;
    if (userProfile == null || authUser == null) return;
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();
    final GlobalKey<FormState> supportFormKey = GlobalKey<FormState>();
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: appThemeColors.primaryWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Написати у підтримку',
            style: TextStyleHelper.instance.title18Bold.copyWith(
              color: appThemeColors.primaryBlack,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: supportFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Опишіть вашу проблему, і ми зв\'яжемося з вами найближчим часом.',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: subjectController,
                    label: 'Тема',
                    hintText: 'Коротко про проблему...',
                    labelColor: appThemeColors.textMediumGrey,
                    inputType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введіть тему звернення';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: messageController,
                    label: 'Повідомлення',
                    hintText: 'Детальний опис...',
                    labelColor: appThemeColors.textMediumGrey,
                    inputType: TextInputType.multiline,
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Введіть текст повідомлення';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Скасувати',
                style: TextStyleHelper.instance.title16Regular.copyWith(
                  color: appThemeColors.errorRed,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (supportFormKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop();
                  try {
                    String userName = 'Користувач';
                    if (userProfile is VolunteerModel) {
                      userName =
                          userProfile.fullName ??
                          userProfile.displayName ??
                          'Волонтер';
                    } else if (userProfile is OrganizationModel) {
                      userName = userProfile.organizationName ?? 'Фонд';
                    } else if (userProfile is AdminModel) {
                      userName = userProfile.fullName ?? 'Адмін';
                    }
                    final newTicketRef = FirebaseFirestore.instance
                        .collection('supportTickets')
                        .doc();
                    final ticket = SupportTicketModel(
                      id: newTicketRef.id,
                      userId: authUser.uid,
                      userName: userName,
                      userPhotoUrl: userProfile.photoUrl,
                      subject: subjectController.text.trim(),
                      message: messageController.text.trim(),
                      status: SupportTicketStatus.open,
                      createdAt: DateTime.now(),
                    );
                    await newTicketRef.set(ticket.toMap());
                    if (mounted) {
                      Constants.showSuccessMessage(
                        context,
                        'Ваш запит успішно відправлено!',
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      Constants.showErrorMessage(
                        context,
                        'Помилка відправки запиту: $e',
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Надіслати',
                style: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showInfoDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemeColors.primaryWhite,
        title: Text(title, style: TextStyleHelper.instance.title18Bold),
        content: Text(
          message,
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: appThemeColors.lightGreenColor,
            ),
            child: Text(
              'Зрозуміло',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController feedbackController =
            TextEditingController();
        return AlertDialog(
          backgroundColor: appThemeColors.primaryWhite,
          title: Text(
            'Зворотній зв\'язок',
            style: TextStyleHelper.instance.title18Bold,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Поділіться своїми думками про додаток',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.textMediumGrey,
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: feedbackController,
                label: 'Відгук',
                hintText: 'Ввідіть ваш відгу...',
                labelColor: appThemeColors.backgroundLightGrey,
                inputType: TextInputType.text,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Будь ласка, введіть відгук';
                  }
                  return null;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Скасувати'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveFeedback(feedbackController.text);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: appThemeColors.blueAccent,
              ),
              child: Text(
                'Надіслати',
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

  Future<void> _saveFeedback(String feedback) async {
    if (feedback.trim().isEmpty) return;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('feedback').add({
          'userId': user.uid,
          'userEmail': user.email,
          'feedback': feedback.trim(),
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'new',
        });
        Constants.showSuccessMessage(context, 'Дякуємо за відгук');
      }
    } catch (e) {
      Constants.showErrorMessage(context, 'Помилка надсилання відгуку');
    }
  }

  void _openPrivacyPolicy() {
    _showInfoDialog(
      'Політика конфіденційності',
      'Ми поважаємо вашу конфіденційність та захищаємо ваші особисті дані.\n\n'
          '• Збираємо мінімум необхідної інформації\n'
          '• Не передаємо дані third-party без згоди\n'
          '• Використовуємо шифрування для захисту\n'
          '• Ви маєте право на видалення даних\n\n'
          'Детальніше можна дізнатися в розділі "Підтримка".',
    );
  }

  void _openTermsOfService() {
    _showInfoDialog(
      'Умови використання',
      'Користуючись HelpHub, ви погоджуєтесь з наступними умовами: \n\n'
          '• Використовувати додаток законно\n'
          '• Поважати інших користувачів\n'
          '• Не порушувати авторські права\n'
          '• Надавати достовірну інформацію\n'
          '• Дотримуватись правил спільноти\n\n'
          'За порушення правил акаунт може бути заблоковано.',
    );
  }

  void _shareApp() {
    final shareText =
        'Приєднуйся до HelpHub - додатку для взаємодопомоги!\n\n'
        'Тут ти можеш знайти допомогу або самостійно допомогти іншим людям.\n\n'
        'Разом ми робимо світ кращим!';
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Widget _buildSignOutButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: appThemeColors.errorRed.withAlpha(187),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: appThemeColors.errorRed.withAlpha(127)),
      ),
      child: Material(
        color: appThemeColors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: _showSignOutDialog,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout,
                  color: appThemeColors.primaryWhite,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Вийти з акаунту',
                  style: TextStyleHelper.instance.title16Bold.copyWith(
                    color: appThemeColors.primaryWhite,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: appThemeColors.primaryWhite,
        title: Text(
          'Вийти з акаунту?',
          style: TextStyleHelper.instance.title18Bold,
        ),
        content: Text(
          'Ви дійсно хочете вийти з вашого акаунту?',
          style: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Скасувати'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.of(context).pop();
                  Navigator.of(
                    context,
                  ).pushReplacementNamed(AppRoutes.splashScreen);
                }
              } catch (e) {
                Navigator.of(context).pop();
                Constants.showErrorMessage(context, 'Помилка виходу з акаунту');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: appThemeColors.errorRed,
            ),
            child: Text(
              'Вийти',
              style: TextStyleHelper.instance.title14Regular.copyWith(
                color: appThemeColors.primaryWhite,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
