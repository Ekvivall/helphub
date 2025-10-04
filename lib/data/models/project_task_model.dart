import 'package:cloud_firestore/cloud_firestore.dart';

enum TaskStatus { pending, inProgress, completed, confirmed }

class ProjectTaskModel {
  final String? id;
  final String? title;
  final String? description;
  final int? neededPeople;
  final List<String>? assignedVolunteerIds;
  final DateTime? deadline;
  final TaskStatus status;
  final String? completedByVolunteerId;

  final DateTime? completionDate;

  ProjectTaskModel({
    this.id,
    this.title,
    this.description,
    this.neededPeople,
    this.assignedVolunteerIds,
    this.deadline,
    this.status = TaskStatus.inProgress,
    this.completedByVolunteerId,
    this.completionDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id':id,
      'title': title,
      'description': description,
      'neededPeople': neededPeople,
      'assignedVolunteerIds': assignedVolunteerIds,
      'deadline': deadline,
      'status': status.name,
      'completedByVolunteerId': completedByVolunteerId,
      'completionDate': completionDate,
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
      completionDate: (map['completionDate'] as Timestamp?)?.toDate(),
      status: map['status'] != null
          ? TaskStatus.values.firstWhere(
              (e) => e.toString() == 'TaskStatus.${map['status']}',
              orElse: () => TaskStatus.pending,
            )
          : TaskStatus.pending,
      completedByVolunteerId: map['completedByVolunteerId'] as String?,
    );
  }

  ProjectTaskModel copyWith({
    String? id,
    String? title,
    String? description,
    int? neededPeople,
    List<String>? assignedVolunteerIds,
    DateTime? deadline,
    DateTime? completionDate,
    TaskStatus? status,
    String? completedByVolunteerId,
  }) {
    return ProjectTaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      neededPeople: neededPeople ?? this.neededPeople,
      assignedVolunteerIds: assignedVolunteerIds ?? this.assignedVolunteerIds,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      completedByVolunteerId:
          completedByVolunteerId ?? this.completedByVolunteerId,
      completionDate: completionDate ?? this.completionDate,
    );
  }
}
