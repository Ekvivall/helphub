import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/fundraiser.dart';

class FundraiserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Adds an entry to users/{uid}/savedFundraisers collection
  Future<void> saveFundraiser(String uid, String fundId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('savedFundraisers')
          .doc(fundId)
          .set({
            'fundraiserId': fundId,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      rethrow;
    }
  }

  //Removes the entry from users/{uid}/savedFundraisers collection
  Future<void> unsaveFundraiser(String uid, String fundId) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('savedFundraisers')
          .doc(fundId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Fundraiser>> getSavedFundraisers(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('savedFundraisers')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((savedSnapshot) async {
          if (savedSnapshot.docs.isEmpty) {
            return [];
          }
          final List<String> fundraiserIds = savedSnapshot.docs
              .map((doc) => doc.id)
              .toList();
          final List<Fundraiser> savedFundraisers = [];
          for (String fundId in fundraiserIds) {
            final docSnapshot = await _firestore
                .collection('fundraisers')
                .doc(fundId)
                .get();
            if (docSnapshot.exists) {
              savedFundraisers.add(
                Fundraiser.fromMap(docSnapshot.id, docSnapshot.data()!),
              );
            }
          }
          return savedFundraisers;
        });
  }
}
