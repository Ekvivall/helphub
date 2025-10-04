import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/models/participant_feedback_model.dart';

import 'organizer_feedback_model.dart';


enum ActivityReportType {
  event,        // Звіт про подію
  project,      // Звіт про проєкт
  fundraising,  // Звіт про збір коштів
}

class ReportModel {
  final String? id;
  final String entityId; // ID події/проєкту/збору
  final ActivityReportType activityType;
  final String activityTitle;
  final String organizerId;
  final String organizerName;
  final String workDescription;
  final List<String> photoUrls;
  final List<String> documentUrls;
  final String? achievements;
  final String? difficulties;
  final List<ParticipantFeedbackModel> participantsFeedback; // Відгуки про учасників від організатора
  final List<OrganizerFeedbackModel> organizerFeedback; // Відгуки про організатора від учасників
  final DateTime createdAt;
  final DateTime? updatedAt;

  final int? participantsCount;
  final double? fundsRaised;
  final int? tasksCompleted;

  ReportModel({
    this.id,
    required this.entityId,
    required this.activityType,
    required this.activityTitle,
    required this.organizerId,
    required this.organizerName,
    required this.workDescription,
    this.photoUrls = const [],
    this.documentUrls = const [],
    this.achievements,
    this.difficulties,
    this.participantsFeedback = const [],
    this.organizerFeedback = const [],
    required this.createdAt,
    this.updatedAt,
    this.participantsCount,
    this.fundsRaised,
    this.tasksCompleted,
  });

  Map<String, dynamic> toMap() {
    return {
      'entityId': entityId,
      'activityType': activityType.name,
      'activityTitle': activityTitle,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'workDescription': workDescription,
      'photoUrls': photoUrls,
      'documentUrls': documentUrls,
      'achievements': achievements,
      'difficulties': difficulties,
      'participantsFeedback': participantsFeedback.map((e) => e.toMap()).toList(),
      'organizerFeedback': organizerFeedback.map((e) => e.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'participantsCount': participantsCount,
      'fundsRaised': fundsRaised,
      'tasksCompleted': tasksCompleted,
    };
  }

  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      id: id,
      entityId: map['entityId'] as String,
      activityType: ActivityReportType.values.firstWhere(
            (e) => e.name == map['activityType'],
        orElse: () => ActivityReportType.event,
      ),
      activityTitle: map['activityTitle'] as String,
      organizerId: map['organizerId'] as String,
      organizerName: map['organizerName'] as String,
      workDescription: map['workDescription'] as String,
      photoUrls: List<String>.from(map['photoUrls'] as List<dynamic>? ?? []),
      documentUrls: List<String>.from(map['documentUrls'] as List<dynamic>? ?? []),
      achievements: map['achievements'] as String?,
      difficulties: map['difficulties'] as String?,
      participantsFeedback: (map['participantsFeedback'] as List<dynamic>?)
          ?.map((e) => ParticipantFeedbackModel.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      organizerFeedback: (map['organizerFeedback'] as List<dynamic>?)
          ?.map((e) => OrganizerFeedbackModel.fromMap(e as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      participantsCount: map['participantsCount'] as int?,
      fundsRaised: (map['fundsRaised'] as num?)?.toDouble(),
      tasksCompleted: map['tasksCompleted'] as int?,
    );
  }

  ReportModel copyWith({
    String? id,
    String? entityId,
    ActivityReportType? activityType,
    String? activityTitle,
    String? organizerId,
    String? organizerName,
    String? workDescription,
    List<String>? photoUrls,
    List<String>? documentUrls,
    String? achievements,
    String? difficulties,
    List<ParticipantFeedbackModel>? participantsFeedback,
    List<OrganizerFeedbackModel>? organizerFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    int? participantsCount,
    double? fundsRaised,
    int? tasksCompleted,
  }) {
    return ReportModel(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      activityType: activityType ?? this.activityType,
      activityTitle: activityTitle ?? this.activityTitle,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      workDescription: workDescription ?? this.workDescription,
      photoUrls: photoUrls ?? this.photoUrls,
      documentUrls: documentUrls ?? this.documentUrls,
      achievements: achievements ?? this.achievements,
      difficulties: difficulties ?? this.difficulties,
      participantsFeedback: participantsFeedback ?? this.participantsFeedback,
      organizerFeedback: organizerFeedback ?? this.organizerFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      participantsCount: participantsCount ?? this.participantsCount,
      fundsRaised: fundsRaised ?? this.fundsRaised,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    );
  }
}