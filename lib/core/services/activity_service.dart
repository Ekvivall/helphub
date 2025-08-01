import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/activity_model.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> logActivity(String uid, ActivityModel activity) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .add(activity.toMap());
    } catch (e) {
      print('Error logging activity: $e');
    }
  }

  Future<void> deleteActivity(
    String uid,
    ActivityType type,
    String entityId,
  ) async {
    try {
      final activityQuery = await _firestore
          .collection('users')
          .doc(uid)
          .collection('activities')
          .where('type', isEqualTo: type.name)
          .where('entityId', isEqualTo: entityId)
          .get();

      for (var doc in activityQuery.docs) {
        await doc.reference.delete();
        print('Activity deleted: ${doc.id} for event $entityId');
      }
    } catch (e) {
      print('Error deleting activity for event $entityId: $e');
    }
  }
}
