import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, file }

class MessageModel {
  final String? id;
  final String senderId;
  final String text;
  final MessageType type;
  final List<String> attachments;
  final DateTime createdAt;
  final List<String> readBy;

  MessageModel({
    this.id,
    required this.senderId,
    required this.text,
    this.type = MessageType.text,
    this.attachments = const [],
    required this.createdAt,
    this.readBy = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'readBy': readBy,
    };
  }

  static MessageModel fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MessageType.text,
      ),
      attachments: List<String>.from(map['attachments'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      readBy: List<String>.from(map['readBy'] ?? []),
    );
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? text,
    MessageType? type,
    List<String>? attachments,
    DateTime? createdAt,
    List<String>? readBy,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      readBy: readBy ?? this.readBy,    );
  }

  bool isReadBy(String userId) => readBy.contains(userId);

  bool get isRead => readBy.isNotEmpty;
}
