import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/chat_model.dart';
import '../../models/message_model.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _chatsCollection = 'chats';
  final String _messagesSubcollection = 'messages';

  Future<String?> createChat({
    required ChatType type,
    String? entityId,
    required List<String> participants,
    String? chatImageUrl,
  }) async {
    try {
      String chatId;

      if (type == ChatType.friend && participants.length == 2) {
        chatId = ChatModel.generateFriendChatId(participants[0], participants[1]);

        final existingChat = await _firestore
            .collection(_chatsCollection)
            .doc(chatId)
            .get();

        if (existingChat.exists) {
          return chatId;
        }
      } else {
        final docRef = _firestore.collection(_chatsCollection).doc();
        chatId = docRef.id;
      }

      final chat = ChatModel(
        id: chatId,
        type: type,
        entityId: entityId,
        participants: participants,
        createdAt: DateTime.now(),
        chatImageUrl: chatImageUrl,
      );

      await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .set(chat.toMap());

      return chatId;
    } catch (e) {
      print('Error creating chat: $e');
      return null;
    }
  }

  Future<bool> sendMessage({
    required String chatId,
    required String text,
    MessageType type = MessageType.text,
    List<String> attachments = const [],
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('User not authenticated');
        return false;
      }

      final messageRef = _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesSubcollection)
          .doc();

      final message = MessageModel(
        id: messageRef.id,
        senderId: currentUser.uid,
        text: text,
        type: type,
        attachments: attachments,
        createdAt: DateTime.now(),
      );

      final batch = _firestore.batch();

      batch.set(messageRef, message.toMap());

      batch.update(
        _firestore.collection(_chatsCollection).doc(chatId),
        {
          'lastMessage': text,
          'lastMessageAt': Timestamp.fromDate(message.createdAt),
        },
      );

      await batch.commit();
      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }

  Stream<List<MessageModel>> listenMessages(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }


  Future<int> getUnreadMessagesCount(String chatId, String userId) async {
    try {
      final unreadQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesSubcollection)
          .where('senderId', isNotEqualTo: userId)
          .get();

      int unreadCount = 0;
      for (var doc in unreadQuery.docs) {
        final message = MessageModel.fromMap(doc.data(), doc.id);
        if (!message.isReadBy(userId)) {
          unreadCount++;
        }
      }

      return unreadCount;
    } catch (e) {
      print('Error getting unread messages count: $e');
      return 0;
    }
  }
  Stream<int> getUnreadMessagesCountStream(String chatId, String userId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .collection(_messagesSubcollection)
        .where('senderId', isNotEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      int unreadCount = 0;
      for (var doc in snapshot.docs) {
        final message = MessageModel.fromMap(doc.data(), doc.id);
        if (!message.readBy.contains(userId)) {
          unreadCount++;
        }
      }
      return unreadCount;
    });
  }

  Stream<int> getTotalUnreadMessagesCount(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .asyncMap((chatsSnapshot) async {
      int totalUnread = 0;

      for (var chatDoc in chatsSnapshot.docs) {
        final unreadCount = await getUnreadMessagesCount(chatDoc.id, userId);
        totalUnread += unreadCount;
      }

      return totalUnread;
    });
  }

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection(_chatsCollection)
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ChatModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<ChatModel?> getChatById(String chatId) async {
    try {
      final doc = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .get();

      if (doc.exists && doc.data() != null) {
        return ChatModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting chat by ID: $e');
      return null;
    }
  }

  Stream<ChatModel> getChatStream(String chatId) {
    return _firestore
        .collection(_chatsCollection)
        .doc(chatId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return ChatModel.fromMap(snapshot.data()!, snapshot.id);
      } else {
        throw Exception('Chat not found or data is empty.');
      }
    });
  }

  Future<bool> addParticipant(String chatId, String userId) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayUnion([userId]),
      });
      return true;
    } catch (e) {
      print('Error adding participant to chat: $e');
      return false;
    }
  }

  Future<bool> removeParticipant(String chatId, String userId) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'participants': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      print('Error removing participant from chat: $e');
      return false;
    }
  }

  Future<String?> createEventChat(
      String eventId,
      List<String> participantIds,
      {String? chatImageUrl}
      ) async {
    return await createChat(
      type: ChatType.event,
      entityId: eventId,
      participants: participantIds,
      chatImageUrl: chatImageUrl,
    );
  }

  Future<String?> createProjectChat(
      String projectId,
      List<String> participantIds,
      {String? chatImageUrl}
      ) async {
    return await createChat(
      type: ChatType.project,
      entityId: projectId,
      participants: participantIds,
      chatImageUrl: chatImageUrl,
    );
  }

  Future<String?> createFriendChat(String userId1, String userId2) async {
    return await createChat(
      type: ChatType.friend,
      participants: [userId1, userId2],
    );
  }

  Future<bool> updateChatImage(String chatId, String? imageUrl) async {
    try {
      await _firestore.collection(_chatsCollection).doc(chatId).update({
        'chatImageUrl': imageUrl,
      });
      return true;
    } catch (e) {
      print('Error updating chat image: $e');
      return false;
    }
  }
  Future<bool> markMessagesAsRead(String chatId, String userId) async {
    try {
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesSubcollection)
          .where('senderId', isNotEqualTo: userId)
          .get();

      final batch = _firestore.batch();

      for (var doc in messagesQuery.docs) {
        final message = MessageModel.fromMap(doc.data(), doc.id);
        if (!message.isReadBy(userId)) {
          batch.update(doc.reference, {
            'readBy': FieldValue.arrayUnion([userId])
          });
        }
      }

      await batch.commit();
      return true;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }

  Future<MessageModel?> getFirstUnreadMessage(String chatId, String userId) async {
    try {
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesSubcollection)
          .where('senderId', isNotEqualTo: userId)
          .orderBy('createdAt', descending: false)
          .get();

      for (var doc in messagesQuery.docs) {
        final message = MessageModel.fromMap(doc.data(), doc.id);
        if (!message.isReadBy(userId)) {
          return message;
        }
      }

      return null;
    } catch (e) {
      print('Error getting first unread message: $e');
      return null;
    }
  }

  Future<bool> deleteChat(String chatId) async {
    try {
      final messagesQuery = await _firestore
          .collection(_chatsCollection)
          .doc(chatId)
          .collection(_messagesSubcollection)
          .get();

      final batch = _firestore.batch();

      for (var doc in messagesQuery.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(_firestore.collection(_chatsCollection).doc(chatId));

      await batch.commit();
      return true;
    } catch (e) {
      print('Error deleting chat: $e');
      return false;
    }
  }
}