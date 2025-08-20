import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/fundraising_model.dart';

import '../../models/fundraiser_application_model.dart';
import '../../models/raffle_winner_model.dart';

class FundraisingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> createFundraising(FundraisingModel fundraising) async {
    try {
      final fundraisingRef = _firestore
          .collection('fundraisings')
          .doc(fundraising.id);
      final newFundraisingId = fundraising.id ?? fundraisingRef.id;
      final fundraisingToSave = fundraising.copyWith(
        id: newFundraisingId,
        timestamp: DateTime.now(),
      );
      await fundraisingRef.set(fundraisingToSave.toMap());
      return newFundraisingId;
    } catch (e) {
      rethrow;
    }
  }

  Future<FundraisingModel?> getFundraisingById(String id) async {
    try {
      final docSnapshot = await _firestore
          .collection('fundraisings')
          .doc(id)
          .get();
      if (docSnapshot.exists && docSnapshot.data() != null) {
        return FundraisingModel.fromMap(docSnapshot.data()!);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateFundraising(FundraisingModel fundraising) async {
    if (fundraising.id == null || fundraising.id!.isEmpty) {
      throw ArgumentError(
        'FundraisingModel must have a non-null ID for update.',
      );
    }
    try {
      await _firestore
          .collection('fundraisings')
          .doc(fundraising.id)
          .update(fundraising.toMap());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteFundraising(String id) async {
    try {
      await _firestore.collection('fundraisings').doc(id).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Завершення збору коштів
  Future<void> completeFundraising(String fundraisingId) async {
    try {
      final batch = _firestore.batch();
      final fundraisingRef = _firestore
          .collection('fundraisings')
          .doc(fundraisingId);
      final fundraisingSnapshot = await fundraisingRef.get();
      if (!fundraisingSnapshot.exists) {
        throw Exception('Збір не знайдено');
      }

      final fundraising = FundraisingModel.fromMap(fundraisingSnapshot.data()!);

      batch.update(fundraisingRef, {'status': 'completed'});

      if (fundraising.relatedApplicationIds != null &&
          fundraising.relatedApplicationIds!.isNotEmpty) {
        for (String applicationId in fundraising.relatedApplicationIds!) {
          final applicationRef = _firestore
              .collection('fundraiserApplications')
              .doc(applicationId);
          batch.update(applicationRef, {
            'status': FundraisingStatus.completed.name,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelFundraising(String fundraisingId, String reason) async {
    try {
      final batch = _firestore.batch();

      final fundraisingRef = _firestore
          .collection('fundraisings')
          .doc(fundraisingId);
      final fundraisingSnapshot = await fundraisingRef.get();

      if (!fundraisingSnapshot.exists) {
        throw Exception('Збір не знайдено');
      }

      final fundraising = FundraisingModel.fromMap(fundraisingSnapshot.data()!);

      batch.update(fundraisingRef, {
        'status': 'cancelled',
        'cancellationReason': reason,
      });

      if (fundraising.relatedApplicationIds != null &&
          fundraising.relatedApplicationIds!.isNotEmpty) {
        for (String applicationId in fundraising.relatedApplicationIds!) {
          final applicationRef = _firestore
              .collection('fundraiserApplications')
              .doc(applicationId);
          batch.update(applicationRef, {
            'status': FundraisingStatus.pending.name,
          });
        }
      }

      await batch.commit();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<FundraisingModel>> getFundraisingsStream() {
    return _firestore
        .collection('fundraisings')
        .where('startDate', isLessThanOrEqualTo: DateTime.now())
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FundraisingModel.fromMap(doc.data()))
              .where((fundraising) {
                return fundraising.status != 'completed';
              })
              .toList();
        });
  }

  Stream<FundraisingModel> getFundraisingStream(String fundraisingId) {
    return _firestore
        .collection('fundraisings')
        .doc(fundraisingId)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            return FundraisingModel.fromMap(snapshot.data()!);
          } else {
            throw Exception('Fundraising not found or data is empty.');
          }
        });
  }

  Future<List<FundraisingModel>> fetchFundraisingsOnce() async {
    try {
      final querySnapshot = await _firestore
          .collection('fundraisings')
          .where('status', isEqualTo: 'active')
          .get();
      return querySnapshot.docs
          .map((doc) => FundraisingModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<FundraisingModel>> getOrganizationFundraisingsStream(
    String organizationId,
  ) {
    return _firestore
        .collection('fundraisings')
        .where('organizationId', isEqualTo: organizationId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FundraisingModel.fromMap(doc.data()))
              .toList();
        });
  }

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

  Stream<List<FundraisingModel>> getSavedFundraisers(String uid) {
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
          final List<FundraisingModel> savedFundraisers = [];
          for (String fundId in fundraiserIds) {
            final docSnapshot = await _firestore
                .collection('fundraisings')
                .doc(fundId)
                .get();
            if (docSnapshot.exists) {
              savedFundraisers.add(
                FundraisingModel.fromMap(docSnapshot.data()!),
              );
            }
          }
          return savedFundraisers;
        });
  }

  Future<bool> isFundraisingSaved(String uid, String fundraisingId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('savedFundraisers')
          .doc(fundraisingId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  Stream<List<FundraisingModel>> getOrganizationActiveFundraisingsStream(
    String organizationId,
  ) {
    return _firestore
        .collection('fundraisings')
        .where('organizationId', isEqualTo: organizationId)
        .where('endDate', isGreaterThanOrEqualTo: DateTime.now())
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FundraisingModel.fromMap(doc.data()))
              .where((fundraising) {
                final now = DateTime.now();
                return fundraising.startDate != null &&
                    fundraising.endDate != null &&
                    now.isAfter(fundraising.startDate!) &&
                    now.isBefore(fundraising.endDate!) &&
                    fundraising.status != 'completed';
              })
              .toList();
        });
  }

  Future<void> saveRaffleWinners(
    String fundraisingId,
    List<RaffleWinnerModel> winners,
  ) async {
    try {
      await _firestore.collection('fundraisings').doc(fundraisingId).update({
        'raffleWinners': winners.map((winner) => winner.toMap()).toList(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
