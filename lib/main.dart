import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:helphub/core/services/notification_service.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth/auth_view_model.dart';
import 'package:helphub/view_models/auth/organization_register_view_model.dart';
import 'package:helphub/view_models/chat/chat_task_view_model.dart';
import 'package:helphub/view_models/chat/chat_view_model.dart';
import 'package:helphub/view_models/donation/donation_view_model.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/view_models/fundraiser_application/fundraiser_application_view_model.dart';
import 'package:helphub/view_models/fundraising/fundraising_view_model.dart';
import 'package:helphub/view_models/notification/notification_view_model.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/view_models/project/project_view_model.dart';
import 'package:helphub/view_models/report/report_view_model.dart';
import 'package:helphub/view_models/splash/splash_view_model.dart';
import 'package:helphub/view_models/auth/volunteer_register_view_model.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

// Обробник фонових повідомлень Firebase
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  timeago.setLocaleMessages('uk', timeago.UkMessages());

  runApp(HelpHubApp());
}

class HelpHubApp extends StatefulWidget {
  const HelpHubApp({super.key});

  @override
  State<HelpHubApp> createState() => _HelpHubAppState();
}

class _HelpHubAppState extends State<HelpHubApp> with WidgetsBindingObserver {
  final AppLifecycleObserver _lifecycleObserver = AppLifecycleObserver();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);

    NotificationService.setNavigatorKey(navigatorKey);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        NotificationService().processPendingNotifications();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SplashViewModel()),
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => VolunteerRegisterViewModel()),
        ChangeNotifierProvider(create: (_) => OrganizationRegisterViewModel()),
        ChangeNotifierProvider(create: (_) => ProfileViewModel()),
        ChangeNotifierProvider(create: (_) => EventViewModel()),
        ChangeNotifierProvider(create: (_) => ProjectViewModel()),
        ChangeNotifierProvider(create: (_) => ChatTaskViewModel()),
        ChangeNotifierProvider(create: (_) => FundraisingViewModel()),
        ChangeNotifierProvider(create: (_) => FundraiserApplicationViewModel()),
        ChangeNotifierProvider(create: (_) => DonationViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => NotificationViewModel()),
      ],
      child: NotificationInitWrapper(
        child: MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          theme: appThemeData,
          initialRoute: AppRoutes.splashScreen,
          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child!,
            );
          },
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('uk', 'UA'), Locale('en', 'US')],
          locale: const Locale('uk', 'UA'),
        ),
      ),
    );
  }
}

class NotificationInitWrapper extends StatefulWidget {
  final Widget child;

  const NotificationInitWrapper({super.key, required this.child});

  @override
  State<NotificationInitWrapper> createState() =>
      _NotificationInitWrapperState();
}

class _NotificationInitWrapperState extends State<NotificationInitWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNotifications();
    });
  }

  Future<void> _initializeNotifications() async {
    try {
      final notificationViewModel = context.read<NotificationViewModel>();
      await notificationViewModel.initialize(context);

      await NotificationService().processPendingNotifications();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}