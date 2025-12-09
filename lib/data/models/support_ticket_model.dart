import 'package:cloud_firestore/cloud_firestore.dart';

enum SupportTicketStatus { open, inProgress, resolved, closed }

class SupportTicketModel {
  final String id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String subject;
  final String message;
  final SupportTicketStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? adminResponse;
  final String? adminId;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.adminResponse,
    this.adminId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'subject': subject,
      'message': message,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'adminResponse': adminResponse,
      'adminId': adminId,
    };
  }

  factory SupportTicketModel.fromMap(Map<String, dynamic> map, String id) {
    return SupportTicketModel(
      id: id,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userPhotoUrl: map['userPhotoUrl'] as String?,
      subject: map['subject'] as String,
      message: map['message'] as String,
      status: SupportTicketStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SupportTicketStatus.open,
      ),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      adminResponse: map['adminResponse'] as String?,
      adminId: map['adminId'] as String?,
    );
  }

  SupportTicketModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhotoUrl,
    String? subject,
    String? message,
    SupportTicketStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? adminResponse,
    String? adminId,
  }) {
    return SupportTicketModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhotoUrl: userPhotoUrl ?? this.userPhotoUrl,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      adminResponse: adminResponse ?? this.adminResponse,
      adminId: adminId ?? this.adminId,
    );
  }
}
