import 'package:flutter/cupertino.dart';
import 'package:helphub/views/auth/register_organization_step1_screen.dart';
import 'package:helphub/views/auth/register_type_screen.dart';
import 'package:helphub/views/auth/register_volunteer_screen.dart';
import 'package:helphub/views/auth/login_screen.dart';
import 'package:helphub/views/splash/splash_screen.dart';

import '../views/auth/register_organization_step2_screen.dart';
import '../views/event/event_map_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String registerTypeScreen = '/register_type';
  static const String registerVolunteerScreen = '/register_volunteer';
  static const String registerOrganizationStep1Screen = '/register_organization_step1';
  static const String registerOrganizationStep2Screen = '/register_organization_step2';
  static const String eventMapScreen = '/event_map';
  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => SplashScreen(),
    loginScreen: (context) => LoginScreen(),
    registerTypeScreen: (context) => RegistrationTypeScreen(),
    registerVolunteerScreen: (context) => RegisterVolunteerScreen(),
    registerOrganizationStep1Screen: (context) => RegisterOrganizationStep1Screen(),
    registerOrganizationStep2Screen: (context) => RegisterOrganizationStep2Screen(),
    eventMapScreen: (context) => EventMapScreen(),
  };
}
