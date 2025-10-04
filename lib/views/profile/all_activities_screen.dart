import 'package:flutter/material.dart';
import 'package:helphub/data/models/activity_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';
import 'package:helphub/widgets/profile/event_organization_activity_item.dart';
import 'package:helphub/widgets/profile/event_participation_activity_item.dart';
import 'package:helphub/widgets/profile/fundraising_creation_activity_item.dart';
import 'package:helphub/widgets/profile/fundraising_donation_activity_item.dart';
import 'package:helphub/widgets/profile/project_organization_activity_item.dart';
import 'package:helphub/widgets/profile/project_participation_activity_item.dart';
import 'package:provider/provider.dart';

import '../../data/models/event_model.dart';
import '../../data/models/fundraising_model.dart';
import '../../data/models/project_model.dart';
import '../../data/models/project_task_model.dart';

class AllActivitiesScreen extends StatefulWidget {
  const AllActivitiesScreen({super.key});

  @override
  State<AllActivitiesScreen> createState() => _AllActivitiesScreenState();
}

class _AllActivitiesScreenState extends State<AllActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Перевірка, чи завершена подія
  bool _isEventCompleted(EventModel? event) {
    if (event == null) return true;
    return event.date.isBefore(DateTime.now());
  }

  // Перевірка, чи завершений проєкт
  bool _isProjectCompleted(ProjectModel? project) {
    if (project == null) return true;
    // Завершений, якщо пройшла дата кінця
    if (project.endDate != null && project.endDate!.isBefore(DateTime.now())) {
      return true;
    }
    // Або якщо всі завдання виконані
    final totalTasks = project.tasks?.length ?? 0;
    if (totalTasks == 0) return false;
    final completedTasks =
        project.tasks?.where((t) => t.status == TaskStatus.confirmed).length ??
        0;
    return totalTasks == completedTasks;
  }

  // Перевірка, чи завершений збір
  bool _isFundraiserCompleted(FundraisingModel? fundraising) {
    if (fundraising == null) return true;
    return fundraising.status == 'completed';
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<ProfileViewModel>(context, listen: false);
    final isOwner =
        viewModel.viewingUserId == null ||
        viewModel.viewingUserId == viewModel.currentAuthUserId;

    return Scaffold(
      backgroundColor: appThemeColors.blueAccent,
      appBar: AppBar(
        backgroundColor: appThemeColors.appBarBg,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.arrow_back,
            size: 40,
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        title: Text(
          'Всі активності',
          style: TextStyleHelper.instance.headline24SemiBold.copyWith(
            color: appThemeColors.backgroundLightGrey,
          ),
        ),
        bottom: TabBar(
          tabAlignment: TabAlignment.start,
          controller: _tabController,
          isScrollable: true,
          labelColor: appThemeColors.backgroundLightGrey,
          unselectedLabelColor: appThemeColors.backgroundLightGrey.withAlpha(
            150,
          ),
          indicatorColor: appThemeColors.lightGreenColor,
          labelStyle: TextStyleHelper.instance.title14Regular.copyWith(
            fontWeight: FontWeight.w600,
          ),
          tabs: const [
            Tab(text: 'Всі'),
            Tab(text: 'Події'),
            Tab(text: 'Проєкти'),
            Tab(text: 'Збори'),
            Tab(text: 'Активні'),
            Tab(text: 'Завершені'),
          ],
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
        child: Consumer<ProfileViewModel>(
          builder: (context, viewModel, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildActivityList(viewModel, isOwner, filter: 'all'),
                _buildActivityList(viewModel, isOwner, filter: 'events'),
                _buildActivityList(viewModel, isOwner, filter: 'projects'),
                _buildActivityList(viewModel, isOwner, filter: 'fundraisers'),
                _buildActivityList(viewModel, isOwner, filter: 'active'),
                _buildActivityList(viewModel, isOwner, filter: 'completed'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActivityList(
    ProfileViewModel viewModel,
    bool isOwner, {
    required String filter,
  }) {
    if (viewModel.isActivitiesLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    // Логіка фільтрації
    final List<ActivityModel> filteredActivities = _getFilteredActivities(
      viewModel,
      filter,
    );

    if (filteredActivities.isEmpty) {
      return _buildEmptyListMessage(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredActivities.length,
      itemBuilder: (context, index) {
        final activity = filteredActivities[index];
        // Використовуємо той самий switch, що і в LatestActivities
        return _buildActivityItem(activity, isOwner, viewModel.currentAuthUserId!);
      },
    );
  }

  List<ActivityModel> _getFilteredActivities(
    ProfileViewModel viewModel,
    String filter,
  ) {
    final allActivities = viewModel.latestActivities;

    switch (filter) {
      case 'events':
        return allActivities
            .where(
              (a) =>
                  a.type == ActivityType.eventParticipation ||
                  a.type == ActivityType.eventOrganization,
            )
            .toList();
      case 'projects':
        return allActivities
            .where(
              (a) =>
                  a.type == ActivityType.projectParticipation ||
                  a.type == ActivityType.projectOrganization,
            )
            .toList();
      case 'fundraisers':
        return allActivities
            .where(
              (a) =>
                  a.type == ActivityType.fundraiserDonation ||
                  a.type == ActivityType.fundraiserCreation,
            )
            .toList();
      case 'active':
        return allActivities.where((a) {
          switch (a.type) {
            case ActivityType.eventParticipation:
            case ActivityType.eventOrganization:
              return !_isEventCompleted(viewModel.eventsData[a.entityId]);
            case ActivityType.projectParticipation:
            case ActivityType.projectOrganization:
              return !_isProjectCompleted(
                viewModel.projectsDataActivities[a.entityId],
              );
            case ActivityType.fundraiserDonation:
            case ActivityType.fundraiserCreation:
              return !_isFundraiserCompleted(
                viewModel.fundraisingsData[a.entityId],
              );
          }
        }).toList();

      case 'completed':
        return allActivities.where((a) {
          switch (a.type) {
            case ActivityType.eventParticipation:
            case ActivityType.eventOrganization:
              return _isEventCompleted(viewModel.eventsData[a.entityId]);
            case ActivityType.projectParticipation:
            case ActivityType.projectOrganization:
              return _isProjectCompleted(viewModel.projectsDataActivities[a.entityId]);
            case ActivityType.fundraiserDonation:
            case ActivityType.fundraiserCreation:
              return _isFundraiserCompleted(
                viewModel.fundraisingsData[a.entityId],
              );
          }
        }).toList();

      case 'all':
      default:
        return allActivities;
    }
  }

  Widget _buildActivityItem(ActivityModel activity, bool isOwner, String currentAuthId) {
    switch (activity.type) {
      case ActivityType.eventParticipation:
        return EventParticipationActivityItem(
          activity: activity,
          isOwner: isOwner,
          currentAuthId: currentAuthId,
        );
      case ActivityType.eventOrganization:
        return EventOrganizationActivityItem(
          activity: activity,
          isOwner: isOwner,
        );
      case ActivityType.projectOrganization:
        return ProjectOrganizationActivityItem(
          activity: activity,
          isOwner: isOwner,
        );
      case ActivityType.fundraiserCreation:
        return FundraisingCreationActivityItem(
          activity: activity,
          isOwner: isOwner,
        );
      case ActivityType.projectParticipation:
        return ProjectParticipationActivityItem(
          activity: activity,
          isOwner: isOwner, currentAuthId: currentAuthId,
        );
      case ActivityType.fundraiserDonation:
        return FundraisingDonationActivityItem(
          activity: activity,
          isOwner: isOwner,
          currentAuthId: currentAuthId,
        );
      // Додайте інші типи активностей, якщо вони є
    }
  }

  Widget _buildEmptyListMessage(String filter) {
    String message;
    switch (filter) {
      case 'events':
        message = 'Немає активностей, пов\'язаних з подіями.';
      case 'projects':
        message = 'Немає активностей, пов\'язаних з проєктами.';
      case 'fundraisers':
        message = 'Немає активностей, пов\'язаних зі зборами.';
      case 'active':
        message = 'Немає активних завдань або подій.';
      case 'completed':
        message = 'Немає завершених активностей.';
      default:
        message = 'Для цього користувача ще немає активностей.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyleHelper.instance.title16Regular.copyWith(
            color: appThemeColors.backgroundLightGrey.withAlpha(150),
          ),
        ),
      ),
    );
  }
}
