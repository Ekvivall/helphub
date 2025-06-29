import 'package:flutter/cupertino.dart';
import 'package:helphub/views/auth/register_organization_screen.dart';
import 'package:helphub/views/auth/register_type_screen.dart';
import 'package:helphub/views/auth/register_volunteer_screen.dart';
import 'package:helphub/views/auth/login_screen.dart';
import 'package:helphub/views/splash/splash_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String registerTypeScreen = '/register_type';
  static const String registerVolunteerScreen = '/register_volunteer';
  static const String registerOrganizationScreen = '/register_organization';
  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => SplashScreen(),
    loginScreen: (context) => LoginScreen(),
    registerTypeScreen: (context) => RegistrationTypeScreen(),
    registerVolunteerScreen: (context) => RegisterVolunteerScreen(),
    registerOrganizationScreen: (context) => RegisterOrganizationScreen(),
  };
}
