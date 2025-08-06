import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/project_task_model.dart';
import 'package:uuid/uuid.dart';

class ProjectModel {
  final String? id;
  final String? title;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<CategoryChipModel>? categories;
  final String? organizerId;
  final String? organizerName;
  final String? city;
  final DateTime? timestamp;
  final List<ProjectTaskModel>? tasks;
  final String? locationText;
  final GeoPoint? locationGeo;
  final List<String>? skills;
  final bool? isOnlyFriends;
  final String? reportId;

  ProjectModel({
    this.id,
    this.title,
    this.description,
    this.startDate,
    this.endDate,
    this.categories,
    this.organizerId,
    this.organizerName,
    this.city,
    this.timestamp,
    this.tasks,
    this.locationText,
    this.locationGeo,
    this.skills,
    this.isOnlyFriends,
    this.reportId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'categories': categories?.map((c) => c.toMap()).toList(),
      'organizerId': organizerId,
      'organizerName': organizerName,
      'city': city,
      'timestamp': timestamp?.toIso8601String(),
      'tasks': tasks
          ?.map((task) => task.toMap()..['id'] = task.id ?? Uuid().v4())
          .toList(),
      'locationText': locationText,
      'locationGeo': locationGeo,
      'skills': skills,
      'isOnlyFriends': isOnlyFriends,
      'reportId': reportId,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map) {
    return ProjectModel(
      id: map['id'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'] as String)
          : null,
      categories: (map['categories'] as List<dynamic>?)
          ?.map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      organizerId: map['organizerId'] as String?,
      organizerName: map['organizerName'] as String?,
      city: map['city'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
      tasks: (map['tasks'] as List<dynamic>?)
          ?.map(
            (e) => ProjectTaskModel.fromMap(
              e as Map<String, dynamic>,
              e['id'] ?? Uuid().v4(),
            ),
          )
          .toList(),
      locationText: map['locationText'] as String?,
      locationGeo: map['locationGeo'] as GeoPoint?,
      skills: (map['skills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      isOnlyFriends: map['isOnlyFriends'] as bool?,
      reportId: map['reportId'] as String?,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    List<CategoryChipModel>? categories,
    String? photoUrl,
    String? organizerId,
    String? organizerName,
    String? city,
    DateTime? timestamp,
    List<ProjectTaskModel>? tasks,
    String? locationText,
    GeoPoint? locationGeo,
    List<String>? skills,
    bool? isOnlyFriends,
    String? reportId,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      categories: categories ?? this.categories,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      city: city ?? this.city,
      timestamp: timestamp ?? this.timestamp,
      tasks: tasks ?? this.tasks,
      locationText: locationText ?? this.locationText,
      locationGeo: locationGeo ?? this.locationGeo,
      skills: skills ?? this.skills,
      isOnlyFriends: isOnlyFriends ?? this.isOnlyFriends,
      reportId: reportId ?? this.reportId,
    );
  }
}
