import 'package:flutter/material.dart';
import 'package:helphub/widgets/profile/fundraising_creation_activity_item.dart';
import 'package:helphub/widgets/profile/project_participation_activity_item.dart';

import '../../data/models/activity_model.dart';
import 'event_organization_activity_item.dart';
import 'event_participation_activity_item.dart';
import 'fundraising_donation_activity_item.dart';
import 'project_organization_activity_item.dart';

class LatestActivities extends StatelessWidget {
  const LatestActivities({
    super.key,
    required this.isOwner,
    required this.displayItems,
    required this.currentAuthId,
  });

  final bool isOwner;
  final List<ActivityModel> displayItems;
  final String currentAuthId;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayItems.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final activity = displayItems[index];
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
              isOwner: isOwner,
              currentAuthId: currentAuthId,
            );
          case ActivityType.fundraiserDonation:
            return FundraisingDonationActivityItem(
              activity: activity,
              isOwner: isOwner,
              currentAuthId: currentAuthId,
            );
        }
      },
    );
  }
}
