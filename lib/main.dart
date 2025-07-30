import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth/auth_view_model.dart';
import 'package:helphub/view_models/auth/organization_register_view_model.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
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
      ),
    );
  }
}
