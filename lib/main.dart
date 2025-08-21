import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth/auth_view_model.dart';
import 'package:helphub/view_models/auth/organization_register_view_model.dart';
import 'package:helphub/view_models/chat/chat_view_model.dart';
import 'package:helphub/view_models/donation/donation_view_model.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/view_models/fundraiser_application/fundraiser_application_view_model.dart';
import 'package:helphub/view_models/fundraising/fundraising_view_model.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/view_models/project/project_view_model.dart';
import 'package:helphub/view_models/report/report_view_model.dart';
import 'package:helphub/view_models/splash/splash_view_model.dart';
import 'package:helphub/view_models/auth/volunteer_register_view_model.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(HelpHubApp());
}

class HelpHubApp extends StatelessWidget {
  const HelpHubApp({super.key});

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
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
        ChangeNotifierProvider(create: (_) => FundraisingViewModel()),
        ChangeNotifierProvider(create: (_) => FundraiserApplicationViewModel()),
        ChangeNotifierProvider(create: (_) => DonationViewModel()),
        ChangeNotifierProvider(create: (_) => ReportViewModel()),
      ],
      child: MaterialApp(
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
        supportedLocales: const [
          Locale('uk', 'UA'),
          Locale('en', 'US'),
        ],
        locale: const Locale('uk', 'UA'),
      ),
    );
  }
}
