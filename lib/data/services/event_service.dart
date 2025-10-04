import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/models/event_model.dart';

import 'chat_service.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'events';

  final ChatService _chatService = ChatService();

  Future<void> createEvent(EventModel event) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      final eventWithId = event.copyWith(id: docRef.id);
      await docRef.set(eventWithId.toMap());
      await _chatService.createEventChat(eventWithId.id!, [event.organizerId]);
    } catch (e) {
      print('Error creating event: $e');
    }
  }

  Stream<EventModel> getEventStream(String eventId) {
    return _firestore.collection(_collectionName).doc(eventId).snapshots().map((
      snapshot,
    ) {
      if (snapshot.exists && snapshot.data() != null) {
        return EventModel.fromMap(snapshot.data()!, snapshot.id);
      } else {
        throw Exception('Event not found or data is empty.');
      }
    });
  }

  Stream<List<EventModel>> getEventsStream() {
    return _firestore.collection(_collectionName).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => EventModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<bool> updateEvent(EventModel event) async {
    if (event.id == null) {
      print('Error: Event ID is null for update operation.');
      return false;
    }
    try {
      await _firestore
          .collection(_collectionName)
          .doc(event.id)
          .update(event.toMap());

      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).delete();
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  Future<bool> addParticipant(String eventId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).update({
        'participantIds': FieldValue.arrayUnion([userId]),
      });
      await addParticipantToEventChat(eventId, userId);
      return true;
    } catch (e) {
      print('Error adding participant: $e');
      return false;
    }
  }

  Future<void> addParticipantToEventChat(String eventId, String userId) async {
    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'event')
          .where('entityId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        final chatId = chatQuery.docs.first.id;
        await _chatService.addParticipant(chatId, userId);
      }
    } catch (e) {
      print('Error adding participant to event chat: $e');
    }
  }

  Future<bool> removeParticipant(String eventId, String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(eventId).update({
        'participantIds': FieldValue.arrayRemove([userId]),
      });
      return true;
    } catch (e) {
      print('Error removing participant: $e');
      return false;
    }
  }

  Future<EventModel?> getEventById(String eventId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(eventId)
          .get();
      if (docSnapshot.exists) {
        return EventModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }

  Future<Map<String, EventModel>> getEventsByIds(List<String> ids) async {
    if (ids.isEmpty) return {};
    final Map<String, EventModel> eventsMap = {};
    final querySnapshot = await _firestore
        .collection(_collectionName)
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    for (var doc in querySnapshot.docs) {
      eventsMap[doc.id] = EventModel.fromMap(doc.data(), doc.id);
    }
    return eventsMap;
  }

  Future<String?> getEventChatId(String eventId) async {
    try {
      final chatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('type', isEqualTo: 'event')
          .where('entityId', isEqualTo: eventId)
          .limit(1)
          .get();

      if (chatQuery.docs.isNotEmpty) {
        return chatQuery.docs.first.id;
      }
    } catch (e) {
      print('Error getting event chat ID: $e');
    }
    return null;
  }
}
