import 'package:cloud_firestore/cloud_firestore.dart';

enum FeedbackStatus {
  unread,
  read,
  processed,
}

class FeedbackModel {
  final String id;
  final String userId;
  final String userEmail;
  final String feedback;
  final DateTime timestamp;
  final FeedbackStatus status;
  final String? adminNote;

  FeedbackModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.feedback,
    required this.timestamp,
    required this.status,
    this.adminNote,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'feedback': feedback,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': status.name,
      'adminNote': adminNote,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map, String id) {
    return FeedbackModel(
      id: id,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      feedback: map['feedback'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: FeedbackStatus.values.firstWhere(
            (e) => e.name == map['status'],
        orElse: () => FeedbackStatus.unread,
      ),
      adminNote: map['adminNote'] as String?,
    );
  }
}