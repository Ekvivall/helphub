import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/follow_model.dart';

class FollowService {
  final CollectionReference _followsCollection = FirebaseFirestore.instance
      .collection('follows');

  Future<void> followOrganization(
    String volunteerUid,
    String organizationUid,
  ) async {
    try {
      final String docId = '${volunteerUid}_$organizationUid';
      final follow = FollowModel(
        id: docId,
        followerId: volunteerUid,
        followedId: organizationUid,
        timestamp: Timestamp.now(),
      );
      await _followsCollection.doc(docId).set(follow.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unfollowOrganization(
    String volunteerUid,
    String organizationUid,
  ) async {
    try {
      final String docId = '${volunteerUid}_$organizationUid';
      await _followsCollection.doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<bool> isFollowing(String volunteerUid, String organizationUid) {
    final String docId = '${volunteerUid}_$organizationUid';
    return _followsCollection
        .doc(docId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }

  Stream<List<String>> getFollowingOrganizations(String volunteerUid) {
    return _followsCollection
        .where('followerId', isEqualTo: volunteerUid)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    (doc.data() as Map<String, dynamic>)['followedId']
                        as String,
              )
              .toList(),
        );
  }

  Stream<int> getFollowersCount(String organizationUid) {
    return _followsCollection
        .where('followedId', isEqualTo: organizationUid)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
}
