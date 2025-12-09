class AdminStatisticsModel {
  final int totalVolunteers;
  final int totalOrganizations;
  final int totalEvents;
  final int totalProjects;
  final int totalFundraisings;
  final int activeUsers;
  final int newUsersThisMonth;
  final Map<String, int> eventsByMonth;
  final Map<String, int> projectsByMonth;
  final List<TopVolunteerModel> topVolunteers;

  AdminStatisticsModel({
    required this.totalVolunteers,
    required this.totalOrganizations,
    required this.totalEvents,
    required this.totalProjects,
    required this.totalFundraisings,
    required this.activeUsers,
    required this.newUsersThisMonth,
    required this.eventsByMonth,
    required this.projectsByMonth,
    required this.topVolunteers,
  });
}


class TopVolunteerModel {
  final String uid;
  final String name;
  final String? photoUrl;
  final int points;
  final int projectsCount;
  final int eventsCount;

  TopVolunteerModel({
    required this.uid,
    required this.name,
    this.photoUrl,
    required this.points,
    required this.projectsCount,
    required this.eventsCount,
  });
}