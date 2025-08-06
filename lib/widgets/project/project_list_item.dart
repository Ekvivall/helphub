import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/constants.dart';
import '../../models/project_model.dart';
import '../../theme/text_style_helper.dart';
import '../../theme/theme_helper.dart';
import '../../view_models/project/project_view_model.dart';
import '../custom_elevated_button.dart';
import '../profile/category_chip_widget.dart';

class ProjectListItem extends StatelessWidget {
  final ProjectModel project;
  final GeoPoint? userCurrentLocation;
  final ProjectViewModel viewModel;

  const ProjectListItem({
    super.key,
    required this.project,
    this.userCurrentLocation,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    final currentUserId = viewModel.user?.uid;
    final isOrganizer = currentUserId == project.organizerId;
    final bool isProjectFinished =
        (project.endDate?.isBefore(DateTime.now()) ?? false);
    final totalNeededPeople = project.tasks
        ?.map((task) => task.neededPeople ?? 0)
        .fold<int>(0, (sum, count) => sum + count);
    final totalVolunteers = project.tasks
        ?.map((task) => task.assignedVolunteerIds?.length ?? 0)
        .fold<int>(0, (sum, count) => sum + count);
    final bool isFull =
        totalVolunteers != null &&
        totalNeededPeople != null &&
        totalVolunteers >= totalNeededPeople;
    final bool isParticipant =
        project.tasks?.any(
          (task) => task.assignedVolunteerIds?.contains(currentUserId) ?? false,
        ) ??
        false;

    String buttonText;
    Color buttonColor;
    VoidCallback? onPressedAction;
    bool isButtonEnabled = true;

    if (isProjectFinished) {
      buttonText = 'Завершено';
      buttonColor = appThemeColors.textLightColor;
      onPressedAction = null;
      isButtonEnabled = false;
    } else if (isOrganizer) {
      buttonText = 'Ви організатор';
      buttonColor = appThemeColors.blueAccent;
      onPressedAction = null;
      isButtonEnabled = false;
    } else if (isParticipant) {
      buttonText = 'Ви долучились';
      buttonColor = appThemeColors.successGreen.withAlpha(175);
      onPressedAction = null;
      isButtonEnabled = false;
    } else if (isFull) {
      buttonText = 'Місць немає';
      buttonColor = appThemeColors.textLightColor;
      onPressedAction = null;
      isButtonEnabled = false;
    } else {
      buttonText = 'Подати заявку';
      buttonColor = appThemeColors.blueAccent;
      onPressedAction = () {
        // TODO: implement logic to apply for a project
      };
    }

    final String distanceText = Constants.calculateDistance(
      project.locationGeo,
      userCurrentLocation,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: appThemeColors.backgroundLightGrey,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title ?? 'Без назви',
                      style: TextStyleHelper.instance.title18Bold.copyWith(
                        color: appThemeColors.primaryBlack,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${totalVolunteers ?? 0}/${totalNeededPeople ?? 0} учасників',
                    style: TextStyleHelper.instance.title14Regular.copyWith(
                      color: appThemeColors.textMediumGrey,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (project.isOnlyFriends!)
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Chip(
                        label: Text(
                          'Приватний',
                          style: TextStyleHelper.instance.title13Regular
                              .copyWith(color: appThemeColors.primaryWhite),
                        ),
                        backgroundColor: appThemeColors.orangeAccent,
                      ),
                    ),
                  if (project.categories != null &&
                      project.categories!.isNotEmpty)
                    ...project.categories!.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CategoryChipWidget(chip: category),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (project.locationText != null)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: appThemeColors.textMediumGrey,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        project.locationText!,
                        style: TextStyleHelper.instance.title14Regular.copyWith(
                          color: appThemeColors.textMediumGrey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (distanceText.isNotEmpty)
                      Row(
                        children: [
                          const SizedBox(width: 8),
                          Icon(
                            Icons.directions_walk,
                            size: 16,
                            color: appThemeColors.textMediumGrey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            distanceText,
                            style: TextStyleHelper.instance.title14Regular
                                .copyWith(color: appThemeColors.textMediumGrey),
                          ),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 12),
              Text(
                project.description ?? '',
                style: TextStyleHelper.instance.title14Regular.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
                textAlign: TextAlign.justify,
              ),
              const SizedBox(height: 12),
              if (project.tasks != null && project.tasks!.isNotEmpty) ...[
                Text(
                  'Завдання:',
                  style: TextStyleHelper.instance.title14Regular.copyWith(
                    color: appThemeColors.primaryBlack,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: project.tasks!.length,
                  itemBuilder: (context, index) {
                    final task = project.tasks!.elementAt(index);
                    final freeSpots =
                        (task.neededPeople ?? 0) - (task.assignedVolunteerIds?.length ?? 0);
                    final isTaskFull = freeSpots <= 0;

                    final formattedDate = DateFormat('d MMM yyyy', 'uk').format(task.deadline!);

                    return Container(
                      color: index % 2 == 0
                          ? appThemeColors.blueMixedColor.withAlpha(75)
                          : Colors.transparent,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                task.title ?? '',
                                style: TextStyleHelper.instance.title14Regular.copyWith(
                                  color: appThemeColors.primaryBlack,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$formattedDate • ',
                                  style: TextStyleHelper.instance.title13Regular.copyWith(
                                    color: appThemeColors.textMediumGrey,
                                  ),
                                ),
                                Text(
                                  isTaskFull
                                      ? 'зайнято'
                                      : '$freeSpots місц${freeSpots == 1 ? 'е' : 'я'} вільно',
                                  style: TextStyleHelper.instance.title13Regular.copyWith(
                                    color: isTaskFull
                                        ? appThemeColors.errorRed
                                        : appThemeColors.successGreen,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 12),
              if (project.skills != null && project.skills!.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: project.skills!.map((skill) {
                    return Chip(
                      padding: const EdgeInsets.all(5),
                      label: Text(skill),
                      backgroundColor: appThemeColors.textMediumGrey,
                      labelStyle: TextStyleHelper.instance.title14Regular
                          .copyWith(color: appThemeColors.primaryWhite),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              CustomElevatedButton(
                onPressed: isButtonEnabled ? onPressedAction : null,
                text: buttonText,
                backgroundColor: buttonColor,
                borderRadius: 10,
                textStyle: TextStyleHelper.instance.title16Bold.copyWith(
                  color: appThemeColors.primaryWhite,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
