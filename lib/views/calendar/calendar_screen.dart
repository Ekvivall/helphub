import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helphub/data/services/event_service.dart';
import 'package:helphub/data/services/project_service.dart';
import 'package:helphub/data/models/base_profile_model.dart';
import 'package:helphub/data/models/project_task_model.dart';
import 'package:helphub/data/models/volunteer_model.dart';
import 'package:helphub/theme/text_style_helper.dart';
import 'package:helphub/theme/theme_helper.dart';
import 'package:helphub/view_models/event/event_view_model.dart';
import 'package:helphub/widgets/custom_bottom_navigation_bar.dart';
import 'package:helphub/widgets/custom_notification_icon_button.dart';
import 'package:helphub/widgets/custom_tournament_icon_button.dart';
import 'package:helphub/widgets/profile/project_organization_activity_item.dart';
import 'package:helphub/widgets/profile/project_participation_activity_item.dart';
import 'package:helphub/widgets/user_avatar_with_frame.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../data/models/activity_model.dart';
import '../../data/models/event_model.dart';
import '../../data/models/project_model.dart';
import '../../view_models/project/project_view_model.dart';
import '../../widgets/profile/event_organization_activity_item.dart';
import '../../widgets/profile/event_participation_activity_item.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final ValueNotifier<List<dynamic>> _selectedEvents;
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final EventService _eventService = EventService();
  final ProjectService _projectService = ProjectService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Map<DateTime, List<CalendarItem>> _eventsByDate = {};
  Map<DateTime, List<CalendarItem>> _projectsByDate = {};

  StreamSubscription<List<EventModel>>? _eventsSubscription;
  StreamSubscription<List<ProjectModel>>? _projectsSubscription;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadData();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    _eventsSubscription?.cancel();
    _projectsSubscription?.cancel();
    super.dispose();
  }

  DateTime _normalizeData(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    // Завантаження подій
    _eventsSubscription?.cancel();
    _eventsSubscription = _eventService.getEventsStream().listen(
      (events) {
        _processEvents(events);
        _checkLoadingComplete();
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Помилка завантаження подій: $error';
          _isLoading = false;
        });
      },
    );
    // Завантаження проєктів
    _projectsSubscription?.cancel();
    _projectsSubscription = _projectService.fetchProjectsStream().listen(
      (projects) {
        _processProjects(projects);
        _checkLoadingComplete();
      },
      onError: (error) {
        setState(() {
          _errorMessage = 'Помилка завантаження проєктів: $error';
          _isLoading = false;
        });
      },
    );
  }

  void _processEvents(List<EventModel> events) {
    final Map<DateTime, List<CalendarItem>> eventsByDate = {};
    for (final event in events) {
      final normalizedDate = _normalizeData(event.date);
      if (eventsByDate[normalizedDate] == null) {
        eventsByDate[normalizedDate] = [];
      }
      eventsByDate[normalizedDate]!.add(CalendarItem(event));
    }
    setState(() {
      _eventsByDate = eventsByDate;
    });
  }

  void _processProjects(List<ProjectModel> projects) {
    final Map<DateTime, List<CalendarItem>> projectsByDate = {};
    final currentUserId = _auth.currentUser?.uid;
    for (final project in projects) {
      // Для учасника показує тільки для завдань, на які він записаний
      if (project.tasks != null) {
        for (final task in project.tasks!) {
          if (task.assignedVolunteerIds?.contains(currentUserId) == true &&
              task.deadline != null) {
            final normalizedDeadline = _normalizeData(task.deadline!);
            if (projectsByDate[normalizedDeadline] == null) {
              projectsByDate[normalizedDeadline] = [];
            }
            if (!projectsByDate[normalizedDeadline]!.contains(
              CalendarItem(project, task: task),
            )) {
              projectsByDate[normalizedDeadline]!.add(
                CalendarItem(project, task: task),
              );
            }
          }
        }
      }
    }
    setState(() {
      _projectsByDate = projectsByDate;
    });
  }

  void _checkLoadingComplete() {
    // Перевірка, чи завантажені події І проєкти
    if (_eventsByDate.isNotEmpty || _projectsByDate.isNotEmpty) {
      setState(() {
        _isLoading = false;
      });
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    }
  }

  List<dynamic> _getEventsForDay(DateTime day) {
    final normalizedDay = _normalizeData(day);
    final events = _eventsByDate[normalizedDay] ?? [];
    final projects = _projectsByDate[normalizedDay] ?? [];
    return [...events, ...projects];
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: appThemeColors.blueAccent,
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
          child: Consumer2<EventViewModel, ProjectViewModel>(
            builder: (context, eventViewModel, projectViewModel, child) {
              if (eventViewModel.user == null &&
                  projectViewModel.user == null) {
                return const SizedBox.shrink();
              }
              final BaseProfileModel user =
                  eventViewModel.user ?? projectViewModel.user!;
              return Column(
                children: [
                  _buildHeader(context, user),
                  Expanded(
                    child: Column(
                      children: [
                        _buildCalendar(),
                        Expanded(
                          child: _buildEventsList(
                            eventViewModel,
                            projectViewModel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  //),
                ],
              );
            },
          ),
        ),
        bottomNavigationBar: buildBottomNavigationBar(context, 3),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BaseProfileModel user) {
    final VolunteerModel? volunteer = user is VolunteerModel ? user : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 12),
      color: appThemeColors.appBarBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          UserAvatarWithFrame(
            size: 22,
            role: user.role,
            photoUrl: user.photoUrl,
            frame: volunteer?.frame,
            uid: user.uid!,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Календар',
              style: TextStyleHelper.instance.title20Regular.copyWith(
                fontWeight: FontWeight.w800,
                color: appThemeColors.backgroundLightGrey,
              ),
            ),
          ),
          CustomTournamentIconButton(),
          CustomNotificationIconButton(),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: appThemeColors.primaryWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: appThemeColors.primaryBlack.withAlpha(9),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar<dynamic>(
        focusedDay: _focusedDay,
        firstDay: DateTime.utc(DateTime.now().year - 1, 1, 1),
        lastDay: DateTime.utc(DateTime.now().year + 1, 12, 31),
        calendarFormat: _calendarFormat,
        eventLoader: _getEventsForDay,
        startingDayOfWeek: StartingDayOfWeek.monday,
        selectedDayPredicate: (day) {
          return isSameDay(_selectedDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          if (!isSameDay(_selectedDay, selectedDay)) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _selectedEvents.value = _getEventsForDay(selectedDay);
          }
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.errorRed,
          ),
          holidayTextStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.errorRed,
          ),
          defaultTextStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.primaryBlack,
          ),
          selectedTextStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.primaryWhite,
            fontWeight: FontWeight.w800,
          ),
          todayTextStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.blueAccent,
            fontWeight: FontWeight.w800,
          ),
          selectedDecoration: BoxDecoration(
            color: appThemeColors.blueAccent,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: appThemeColors.blueMixedColor,
            shape: BoxShape.circle,
            border: Border.all(color: appThemeColors.blueAccent, width: 2),
          ),
          markerDecoration: BoxDecoration(
            color: appThemeColors.successGreen,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
          canMarkersOverflow: true,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyleHelper.instance.title18Bold.copyWith(
            color: appThemeColors.primaryBlack,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: appThemeColors.blueAccent,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: appThemeColors.blueAccent,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.textMediumGrey,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyleHelper.instance.title14Regular.copyWith(
            color: appThemeColors.errorRed,
            fontWeight: FontWeight.w600,
          ),
        ),
        locale: 'uk_UA',
      ),
    );
  }

  Widget _buildEventsList(
    EventViewModel eventViewModel,
    ProjectViewModel projectViewModel,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 9),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: appThemeColors.backgroundLightGrey,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: appThemeColors.blueAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                _selectedDay != null
                    ? 'Події на ${DateFormat('d MMMM yyyy', 'uk').format(_selectedDay!)}'
                    : 'Виберіть дату',
                style: TextStyleHelper.instance.title18Bold.copyWith(
                  color: appThemeColors.primaryBlack,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: appThemeColors.successGreen,
                    ),
                  )
                : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyleHelper.instance.title16Regular.copyWith(
                          color: appThemeColors.errorRed,
                        ),
                      ),
                    ),
                  )
                : ValueListenableBuilder<List<dynamic>>(
                    valueListenable: _selectedEvents,
                    builder: (context, events, _) {
                      if (events.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_busy,
                                size: 64,
                                color: appThemeColors.textMediumGrey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Подій на цю дату немає',
                                textAlign: TextAlign.center,
                                style: TextStyleHelper.instance.title16Regular
                                    .copyWith(
                                      color: appThemeColors.textMediumGrey,
                                    ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final CalendarItem calendarItem = events[index];
                          String currentAuthId = _auth.currentUser!.uid;
                          if (calendarItem.isEvent) {
                            EventModel event = calendarItem.item;

                            ActivityModel activity = ActivityModel(
                              type: ActivityType.eventParticipation,
                              entityId: event.id!,
                              title: event.name,
                              description: event.description,
                              timestamp: DateTime.now(),
                            );
                            if (currentAuthId == event.organizerId) {
                              return EventOrganizationActivityItem(
                                activity: activity,
                                isOwner: true,
                              );
                            } else {
                              return EventParticipationActivityItem(
                                activity: activity,
                                isOwner: true,
                                currentAuthId: currentAuthId,
                              );
                            }
                          }
                          ProjectModel project = calendarItem.item;
                          ProjectTaskModel task = calendarItem.task!;
                          ActivityModel activity = ActivityModel(
                            type: ActivityType.eventParticipation,
                            entityId: project.id!,
                            title:
                                'Завдання "${task.title}" в проєкті "${project.title}"',
                            description: task.description,
                            timestamp: DateTime.now(),
                          );
                          if (currentAuthId == project.organizerId) {
                            return ProjectOrganizationActivityItem(
                              activity: activity,
                              isOwner: true,
                            );
                          } else {
                            return ProjectParticipationActivityItem(
                              activity: activity,
                              isOwner: true,
                              currentAuthId: currentAuthId,
                            );
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class CalendarItem {
  final dynamic item; // Може бути EventModel або ProjectModel
  final ProjectTaskModel? task; // Опціонально, для завдань проєкту

  CalendarItem(this.item, {this.task});

  bool get isEvent => item is EventModel;

  bool get isProject => item is ProjectModel;
}
