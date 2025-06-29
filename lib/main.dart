import 'package:flutter/material.dart';
import 'package:helphub/routes/app_router.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/auth_view_model.dart';
import 'package:helphub/view_models/splash_view_model.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HelpHubApp());
}

class HelpHubApp extends StatelessWidget {
  const HelpHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(providers: [
      ChangeNotifierProvider(create: (_) =>
          SplashViewModel()
      ),
      ChangeNotifierProvider(create: (_) => AuthViewModel())
    ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: appThemeData,
        initialRoute: AppRoutes.splashScreen,
        routes: AppRoutes.routes,
        builder: (context, child) {
          return MediaQuery(data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0)), child: child!);
        },
      ),
    );
  }
}
