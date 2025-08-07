import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/event_model.dart';

class EventService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'events';

  Future<void> createEvent(EventModel event) async {
    try {
      final docRef = _firestore.collection(_collectionName).doc();
      final eventWithId = event.copyWith(id: docRef.id);
      await docRef.set(eventWithId.toMap());
    } catch (e) {
      print('Error creating event: $e');
    }
  }

  Stream<EventModel> getEventStream(String eventId) {
    return _firestore.collection(_collectionName).doc(eventId).snapshots().map((snapshot){
      if(snapshot.exists && snapshot.data() != null){
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
      return true;
    } catch (e) {
      print('Error adding participant: $e');
      return false;
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
      final docSnapshot = await _firestore.collection(_collectionName).doc(eventId).get();
      if (docSnapshot.exists) {
        return EventModel.fromMap(docSnapshot.data()!, docSnapshot.id);
      }
      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }
}
