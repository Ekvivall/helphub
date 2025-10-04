import 'package:cloud_firestore/cloud_firestore.dart';

class ProjectApplicationModel {
  final String id;
  final String volunteerId;
  final String projectId;
  final String? taskId;
  final String? message;
  final String status;
  final Timestamp timestamp;

  ProjectApplicationModel({
    required this.id,
    required this.volunteerId,
    required this.projectId,
    this.taskId,
    this.message,
    this.status = 'pending',
    required this.timestamp,
  });

  factory ProjectApplicationModel.fromMap(String id, Map<String, dynamic> map) {
    return ProjectApplicationModel(
      id: id,
      volunteerId: map['volunteerId'] as String,
      projectId: map['projectId'] as String,
      taskId: map['taskId'] as String?,
      message: map['message'] as String?,
      status: map['status'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'projectId': projectId,
      'taskId': taskId,
      'message': message,
      'status': status,
      'timestamp': timestamp,
    };
  }
}