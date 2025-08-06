import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectTaskModel {
  final String? id;
  final String? title;
  final String? description;
  final int? neededPeople;
  final List<String>? assignedVolunteerIds;
  final DateTime? deadline;

  ProjectTaskModel({
    this.id,
    this.title,
    this.description,
    this.neededPeople,
    this.assignedVolunteerIds,
    this.deadline,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'neededPeople': neededPeople,
      'assignedVolunteerIds': assignedVolunteerIds,
      'deadline': deadline,
    };
  }

  factory ProjectTaskModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectTaskModel(
      id: id,
      title: map['title'] as String?,
      description: map['description'] as String?,
      neededPeople: map['neededPeople'] as int?,
      assignedVolunteerIds: (map['assignedVolunteerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      deadline: (map['deadline'] as Timestamp?)?.toDate(),
    );
  }

  ProjectTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? neededPeople,
    List<String>? assignedVolunteerIds,
    DateTime? deadline,
  }) {
    return ProjectTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      neededPeople: neededPeople ?? this.neededPeople,
      assignedVolunteerIds: assignedVolunteerIds ?? this.assignedVolunteerIds,
      deadline: deadline ?? this.deadline,
    );
  }
}
