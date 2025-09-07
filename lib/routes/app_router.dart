import 'package:flutter/material.dart';
import 'package:helphub/models/activity_model.dart';
import 'package:helphub/models/fundraising_model.dart';
import 'package:helphub/views/auth/forgot_password_screen.dart';
import 'package:helphub/views/auth/register_organization_step1_screen.dart';
import 'package:helphub/views/auth/register_type_screen.dart';
import 'package:helphub/views/auth/register_volunteer_screen.dart';
import 'package:helphub/views/auth/login_screen.dart';
import 'package:helphub/views/calendar/calendar_screen.dart';
import 'package:helphub/views/chat/chat_event_screen.dart';
import 'package:helphub/views/chat/chat_project_screen.dart';
import 'package:helphub/views/event/create_event_screen.dart';
import 'package:helphub/views/event/event_detail_screen.dart';
import 'package:helphub/views/event/event_list_screen.dart' hide DisplayMode;
import 'package:helphub/views/fundraising/donation_screen.dart';
import 'package:helphub/views/fundraising/fundraising_details_screen.dart';
import 'package:helphub/views/fundraising/fundraising_donations_screen.dart';
import 'package:helphub/views/fundraising/fundraising_list_screen.dart';
import 'package:helphub/views/fundraising/fundraising_raffle_screen.dart';
import 'package:helphub/views/profile/all_applications_screen.dart';
import 'package:helphub/views/profile/all_followed_organizations_screen.dart';
import 'package:helphub/views/profile/all_saved_fundraisers_screen.dart';
import 'package:helphub/views/profile/edit_user_profile_screen.dart';
import 'package:helphub/views/profile/find_friends_screen.dart';
import 'package:helphub/views/profile/friends_list_screen.dart';
import 'package:helphub/views/profile/organization_profile_screen.dart';
import 'package:helphub/views/profile/volunteer_profile_screen.dart';
import 'package:helphub/views/project/apply_to_project_screen.dart';
import 'package:helphub/views/project/project_list_screen.dart';
import 'package:helphub/views/report/create_report_screen.dart';
import 'package:helphub/views/report/view_report_screen.dart';
import 'package:helphub/views/splash/splash_screen.dart';

import '../views/auth/register_organization_step2_screen.dart';
import '../views/chat/chat_friend_screen.dart';
import '../views/chat/chat_list_screen.dart';
import '../views/event/event_map_screen.dart';
import '../views/fundraising/create_fundraising_application_screen.dart';
import '../views/fundraising/create_fundraising_screen.dart';
import '../views/profile/all_activities_screen.dart';
import '../views/profile/all_fundraiser_applications_screen.dart';
import '../views/profile/friend_requests_screen.dart';
import '../views/project/create_project_screen.dart';

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
  static const String eventListScreen = '/event_list';
  static const String eventDetailScreen = '/event_detail';
  static const String createEventScreen = '/create_event';
  static const String createProjectScreen = '/create_project';
  static const String projectListScreen = '/project_list';
  static const String applyToProjectScreen = '/apply_to_project';
  static const String chatProjectScreen = '/chat_project';
  static const String createFundraisingScreen = '/create_fundraising';
  static const String fundraisingListScreen = '/fundraising_list';
  static const String createFundraisingApplicationScreen =
      '/create_fundraising_application';
  static const String allApplicationsScreen = '/all_applications';
  static const String allFundraiserApplicationsScreen =
      '/all_fundraiser_applications';
  static const String fundraisingDetailScreen = '/fundraising_detail';
  static const String donationScreen = '/donation';
  static const String allSavedFundraisersScreen = '/all_saved_fundraisers';
  static const String fundraisingDonationsScreen = '/fundraising_donations';
  static const String fundraisingRaffleScreen = '/fundraising_raffle';
  static const String createReportScreen = '/create_report';
  static const String allActivitiesScreen = '/all_activities';
  static const String viewReportScreen = '/view_report';
  static const String chatListScreen = '/chat_list';
  static const String chatFriendScreen = '/chat_friend';
  static const String chatEventScreen = '/chat_event';
  static const String calendarScreen = '/calendar';



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
    projectListScreen: (context) => ProjectListScreen(),
    fundraisingListScreen: (context) => FundraisingListScreen(),
    allApplicationsScreen: (context) => AllApplicationsScreen(),
    allFundraiserApplicationsScreen: (context) =>
        AllFundraiserApplicationsScreen(),
    allSavedFundraisersScreen: (context) => AllSavedFundraisersScreen(),
    allActivitiesScreen: (context) => AllActivitiesScreen(),
    chatListScreen: (context) => ChatListScreen(),
    calendarScreen: (context) => CalendarScreen(),
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
      case createProjectScreen:
        final String projectId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => CreateProjectScreen(projectId: projectId),
        );
      case applyToProjectScreen:
        final String projectId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => ApplyToProjectScreen(projectId: projectId),
        );
      case chatProjectScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ChatProjectScreen(
            chatId: args?['chatId'] as String,
            initialDisplayMode:
                args?['displayMode'] as DisplayMode? ?? DisplayMode.chat,
          ),
        );
      case createFundraisingScreen:
        final String fundraisingId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              CreateFundraisingScreen(fundraisingId: fundraisingId),
        );
      case createFundraisingApplicationScreen:
        final String organizationId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) => CreateFundraisingApplicationScreen(
            organizationId: organizationId,
          ),
        );
      case fundraisingDetailScreen:
        final String fundraisingId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              FundraisingDetailScreen(fundraisingId: fundraisingId),
        );
      case donationScreen:
        final fundraising = settings.arguments as FundraisingModel;
        return MaterialPageRoute(
          builder: (context) => DonationScreen(fundraising: fundraising),
        );
      case fundraisingDonationsScreen:
        final fundraisingId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              FundraisingDonationsScreen(fundraisingId: fundraisingId),
        );
      case fundraisingRaffleScreen:
        final fundraisingId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              FundraisingRaffleScreen(fundraisingId: fundraisingId),
        );
      case createReportScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => CreateReportScreen(
            reportId: args?['reportId'] as String?,
            activity: args?['activity'] as ActivityModel?,
          ),
        );
      case viewReportScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (context) => ViewReportScreen(
            reportId: args?['reportId'] as String,
            canLeaveFeedback: args?['canLeaveFeedback'] as bool,
          ),
        );
      case chatFriendScreen:
        final chatId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              ChatFriendScreen(chatId: chatId),
        );
      case chatEventScreen:
        final chatId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (context) =>
              ChatEventScreen(chatId: chatId),
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
