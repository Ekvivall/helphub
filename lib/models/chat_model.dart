import 'package:cloud_firestore/cloud_firestore.dart';

enum ChatType { event, project, friend }

class ChatModel {
  final String? id;
  final ChatType type;
  final String? entityId;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;

  ChatModel({
    this.id,
    required this.type,
    this.entityId,
    required this.participants,
    this.lastMessage,
    this.lastMessageAt,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'entityId': entityId,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : null,
    };
  }

  static ChatModel fromMap(Map<String, dynamic> map, String id) {
    return ChatModel(
      id: id,
      type: ChatType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => ChatType.friend,
      ),
      entityId: map['entityId'],
      participants: List<String>.from(map['participants'] ?? []),
      lastMessage: map['lastMessage'],
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  ChatModel copyWith({
    String? id,
    ChatType? type,
    String? entityId,
    List<String>? participants,
    String? lastMessage,
    DateTime? lastMessageAt,
    DateTime? createdAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      type: type ?? this.type,
      entityId: entityId ?? this.entityId,
      participants: participants ?? this.participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static String generateFriendChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return 'friend_${sortedIds[0]}_${sortedIds[1]}';
  }

  bool isParticipant(String userId) {
    return participants.contains(userId);
  }
}
