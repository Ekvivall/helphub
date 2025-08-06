import 'package:flutter/material.dart';
import 'package:helphub/view_models/profile/profile_view_model.dart';

import '../../models/activity_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import 'event_organization_activity_item.dart';
import 'event_participation_activity_item.dart';
import 'project_organization_activity_item.dart';

class LatestActivities extends StatelessWidget {
  const LatestActivities({
    super.key,
    required this.isOwner, required this.viewModel,
  });

  final bool isOwner;
  final ProfileViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: viewModel.latestActivities.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final activity =
        viewModel.latestActivities[index];
        switch (activity.type) {
          case ActivityType.eventParticipation:
            return EventParticipationActivityItem(
              activity: activity, isOwner: isOwner,
            );
        // TODO: Додати інші типи активностей тут
          case ActivityType.eventOrganization:
            return EventOrganizationActivityItem(
              activity: activity, isOwner: isOwner,
            );
          case ActivityType.projectTaskCompletion:
            return Text(
              'Виконано завдання в проекті: ${activity
                  .title}',
              style: TextStyleHelper
                  .instance
                  .title16Regular
                  .copyWith(
                color: appThemeColors
                    .backgroundLightGrey,
              ),
            );
          case ActivityType.projectOrganization:
            return ProjectOrganizationActivityItem(
                activity: activity, isOwner: isOwner);
          case ActivityType.fundraiserCreation:
            return Text(
              'Створено збір коштів: ${activity.title}',
              style: TextStyleHelper
                  .instance
                  .title16Regular
                  .copyWith(
                color: appThemeColors
                    .backgroundLightGrey,
              ),
            );
        }
      },
    );
  }
}