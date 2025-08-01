import 'package:cloud_firestore/cloud_firestore.dart';

enum ActivityType {
  eventParticipation, // Користувач взяв участь у події
  eventOrganization,  // Користувач був організатором події
  projectTaskCompletion, // Завдання в проекті виконано
  projectNewApplication, // Нова заявка на проект
  fundraiserCreation, // Створено новий збір коштів
}

class ActivityModel {
  final ActivityType type;
  final String entityId;
  final String title;
  final String? description;
  final DateTime timestamp;

  ActivityModel({
    required this.type,
    required this.entityId,
    required this.title,
    this.description,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'entityId': entityId,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ActivityModel.fromMap(Map<String, dynamic> map) {
    return ActivityModel(
      type: ActivityType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ActivityType.eventParticipation,
      ),
      entityId: map['entityId'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}