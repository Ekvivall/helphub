import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:helphub/views/auth/forgot_password_screen.dart';
import 'package:helphub/views/auth/register_organization_step1_screen.dart';
import 'package:helphub/views/auth/register_type_screen.dart';
import 'package:helphub/views/auth/register_volunteer_screen.dart';
import 'package:helphub/views/auth/login_screen.dart';
import 'package:helphub/views/event/create_event_screen.dart';
import 'package:helphub/views/event/event_detail_screen.dart';
import 'package:helphub/views/event/event_list_screen.dart';
import 'package:helphub/views/profile/all_followed_organizations_screen.dart';
import 'package:helphub/views/profile/edit_user_profile_screen.dart';
import 'package:helphub/views/profile/find_friends_screen.dart';
import 'package:helphub/views/profile/friends_list_screen.dart';
import 'package:helphub/views/profile/organization_profile_screen.dart';
import 'package:helphub/views/profile/volunteer_profile_screen.dart';
import 'package:helphub/views/splash/splash_screen.dart';

import '../views/auth/register_organization_step2_screen.dart';
import '../views/event/event_map_screen.dart';
import '../views/profile/friend_requests_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String loginScreen = '/login';
  static const String registerTypeScreen = '/register_type';
  static const String registerVolunteerScreen = '/register_volunteer';
  static const String registerOrganizationStep1Screen =
      '/register_organization_step1';
  static const String registerOrganizationStep2Screen =
      '/register_organization_step2';
  static const String eventMapScreen = '/event_map';
  static const String volunteerProfileScreen = '/volunteer_profile';
  static const String organizationProfileScreen = '/organization_profile';
  static const String editUserProfileScreen = '/edit_user_profile';
  static const String forgotPasswordScreen = '/forgot_password';
  static const String findFriendsScreen = '/find_friends';
  static const String friendRequestsScreen = '/friend_requests';
  static const String friendsListScreen = '/friends_list';
  static const String allFollowedOrganizationsScreen =
      '/all_followed_organizations';
  static const String eventListScreen = 'event_list';
  static const String eventDetailScreen = 'event_detail';
  static const String createEventScreen = 'create_event';
  static Map<String, WidgetBuilder> routes = {
    splashScreen: (context) => SplashScreen(),
    loginScreen: (context) => LoginScreen(),
    registerTypeScreen: (context) => RegistrationTypeScreen(),
    registerVolunteerScreen: (context) => RegisterVolunteerScreen(),
    registerOrganizationStep1Screen: (context) =>
        RegisterOrganizationStep1Screen(),
    registerOrganizationStep2Screen: (context) =>
        RegisterOrganizationStep2Screen(),
    eventMapScreen: (context) => EventMapScreen(),
    editUserProfileScreen: (context) => EditUserProfileScreen(),
    forgotPasswordScreen: (context) => ForgotPasswordScreen(),
    findFriendsScreen: (context) => FindFriendsScreen(),
    friendRequestsScreen: (context) => FriendRequestsScreen(),
    friendsListScreen: (context) => FriendsListScreen(),
    allFollowedOrganizationsScreen: (context) =>
        AllFollowedOrganizationsScreen(),
    eventListScreen: (context) => EventListScreen(),
  };

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case volunteerProfileScreen:
        final String? userId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (context) => VolunteerProfileScreen(userId: userId),
        );
      case organizationProfileScreen:
        final String? userId = settings.arguments as String?;
        return MaterialPageRoute(
          builder: (context) => OrganizationProfileScreen(userId: userId),
        );
      case eventDetailScreen:
        final String eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => EventDetailScreen(eventId: eventId),
        );
      case createEventScreen:
        final String eventId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => CreateEventScreen(eventId: eventId),
        );
      default:
        if (routes.containsKey(settings.name)) {
          return MaterialPageRoute(
            builder: routes[settings.name]!,
            settings: settings,
          );
        }
        return MaterialPageRoute(
          builder: (context) =>
              const Scaffold(body: Center(child: Text('Error: Unknown route'))),
        );
    }
  }
}
