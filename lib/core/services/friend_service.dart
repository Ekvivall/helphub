import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:helphub/models/friend_request_model.dart';

class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  Future<void> sendFriendRequest(String receiverId) async {
    if (currentUserId == null) return;
    final senderProfile = await _firestore
        .collection('users')
        .doc(currentUserId)
        .get();
    String senderDisplayName = 'Невідомий';
    if (senderProfile.exists) {
      senderDisplayName =
          senderProfile.data()?['fullName'] as String? ??
          senderProfile.data()?['displayName'] as String? ??
          'Невідомий';
    }

    final friendRequest = FriendRequestModel(
      senderId: currentUserId!,
      receiverId: receiverId,
      status: FriendRequestStatus.pending,
      timestamp: DateTime.now(),
      senderDisplayName:
          senderDisplayName,
      senderPhotoUrl: senderProfile.data()?['photoUrl'] as String?
    );
    await _firestore.collection('friendRequests').add(friendRequest.toMap());
  }

  Future<void> acceptFriendRequest(
    String senderId,
  ) async {
    final batch = _firestore.batch();
    final query = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get();
    for (var doc in query.docs) {
      batch.delete(doc.reference);
    }
    final currentUserFriendsRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(senderId);
    batch.set(currentUserFriendsRef, {'addedAt': FieldValue.serverTimestamp()});
    final senderFriendsRef = _firestore
        .collection('users')
        .doc(senderId)
        .collection('friends')
        .doc(currentUserId);
    batch.set(senderFriendsRef, {'addedAt': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Future<void> rejectFriendRequest(
    String senderId,
  ) async {
    await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: senderId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('status', isEqualTo: 'pending')
        .get()
        .then((snapshot) {
          for (var doc in snapshot.docs) {
            doc.reference.delete();
          }
        });
  }

  Stream<List<FriendRequestModel>> listenToIncomingRequests() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: currentUserId)
        .where(
          'status',
          isEqualTo: FriendRequestStatus.pending.toString().split('.').last,
        )
        .snapshots()
        .asyncMap((snapshot) async {
          final List<FriendRequestModel> requests = [];
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final friendRequest = FriendRequestModel.fromMap(data, id: doc.id);
            final senderId = friendRequest.senderId;
            final senderDoc = await _firestore
                .collection('users')
                .doc(senderId)
                .get();
            String senderDisplayName = 'Невідомий';
            String? senderPhotoUrl;
            if (senderDoc.exists) {
              final senderData = senderDoc.data();
              if (senderData != null) {
                senderDisplayName =
                    senderData['fullName'] as String? ??
                    senderData['displayName'] as String? ??
                    'Невідомий';
                senderPhotoUrl = senderData['photoUrl'] as String?;
              }
            }
            requests.add(
              friendRequest.copyWith(
                senderDisplayName: senderDisplayName,
                senderPhotoUrl: senderPhotoUrl,
              ),
            );
          }
          return requests;
        });
  }

  Stream<List<String>> getFriendList() {
    if (currentUserId == null) {
      return Stream.value([]);
    }
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<void> unfriend(String friendId) async {
    if (currentUserId == null) {
      throw Exception('Користувач не авторизований.');
    }
    final batch = _firestore.batch();
    final currentUserRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('friends')
        .doc(friendId);
    batch.delete(currentUserRef);
    final friendUserRef = _firestore
        .collection('users')
        .doc(friendId)
        .collection('friends')
        .doc(currentUserId);
    batch.delete(friendUserRef);
    // Видалення пов'язаних запитів на дружбу між ними
    final query1 = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUserId)
        .where('receiverId', isEqualTo: friendId)
        .get();
    final query2 = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: friendId)
        .where('receiverId', isEqualTo: currentUserId)
        .get();
    for (var doc in query1.docs) {
      batch.delete(doc.reference);
    }
    for (var doc in query2.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<bool> hasSentFriendRequest(
    String? currentAuthUserId,
    String targetUserId,
  ) async {
    final query = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentAuthUserId)
        .where('receiverId', isEqualTo: targetUserId)
        .where(
          'status',
          isEqualTo: FriendRequestStatus.pending.toString().split('.').last,
        )
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> hasReceivedFriendRequest(
    String? currentAuthUserId,
    String targetUserId,
  ) async {
    final query = await _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: targetUserId)
        .where('receiverId', isEqualTo: currentAuthUserId)
        .where(
          'status',
          isEqualTo: FriendRequestStatus.pending.toString().split('.').last,
        )
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  Future<bool> areFriends(String userId1, String userId2) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId1)
        .collection('friends')
        .doc(userId2)
        .get();
    return doc.exists;
  }
}
