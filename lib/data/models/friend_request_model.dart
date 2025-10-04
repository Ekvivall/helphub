import 'package:cloud_firestore/cloud_firestore.dart';

enum FriendRequestStatus {
  pending, //Запит очікує на розгляд
}

enum FriendshipStatus {
  notFriends,
  requestSent,
  requestReceived,
  friends,
  self,
}

class FriendRequestModel {
  final String? id;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime timestamp;
  final String senderDisplayName;
  final String? senderPhotoUrl;

  FriendRequestModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
    required this.senderDisplayName,
    this.senderPhotoUrl,
  });

  factory FriendRequestModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return FriendRequestModel(
      id: id,
      senderId: map['senderId'] as String,
      receiverId: map['receiverId'] as String,
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['status'],
        orElse: () => FriendRequestStatus.pending,
      ),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      senderDisplayName: map['senderDisplayName'] as String? ?? 'Невідомий',
      senderPhotoUrl: map['senderPhotoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'senderDisplayName': senderDisplayName,
      'senderPhotoUrl': senderPhotoUrl,
    };
  }

  FriendRequestModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    FriendRequestStatus? status,
    DateTime? timestamp,
    String? senderDisplayName,
    String? senderPhotoUrl,
  }) {
    return FriendRequestModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      senderDisplayName: senderDisplayName ?? this.senderDisplayName,
      senderPhotoUrl: senderPhotoUrl ?? this.senderPhotoUrl,
    );
  }
}
