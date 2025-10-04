import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/donation_model.dart';

class DonationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Додавання донату
  Future<String> addDonation(DonationModel donation) async {
    try {
      final batch = _firestore.batch();

      final donationRef = _firestore.collection('donations').doc();
      final donationToSave = donation.copyWith(
        id: donationRef.id,
        timestamp: DateTime.now(),
      );

      batch.set(donationRef, donationToSave.toMap());

      final fundraisingRef = _firestore
          .collection('fundraisings')
          .doc(donation.fundraisingId);

      batch.update(fundraisingRef, {
        'donorIds': FieldValue.arrayUnion([donation.donorId]),
        'currentAmount': FieldValue.increment(donation.amount),
      });
      await batch.commit();
      return donationRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Отримати всі донати для конкретного збору
  Stream<List<DonationModel>> getFundraisingDonations(String fundraisingId) {
    return _firestore
        .collection('donations')
        .where('fundraisingId', isEqualTo: fundraisingId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Отримати донати конкретного користувача
  Stream<List<DonationModel>> getUserDonations(String userId) {
    return _firestore
        .collection('donations')
        .where('donorId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => DonationModel.fromMap(doc.data()))
          .toList();
    });
  }

  // Отримати статистику донатів для збору
  Future<Map<String, dynamic>> getFundraisingDonationStats(
      String fundraisingId,) async {
    try {
      final querySnapshot = await _firestore
          .collection('donations')
          .where('fundraisingId', isEqualTo: fundraisingId)
          .get();

      double totalAmount = 0;
      int donationCount = querySnapshot.docs.length;
      Set<String> uniqueDonors = {};

      for (var doc in querySnapshot.docs) {
        final donation = DonationModel.fromMap(doc.data());
        totalAmount += donation.amount;
        uniqueDonors.add(donation.donorId);
      }

      return {
        'totalAmount': totalAmount,
        'donationCount': donationCount,
        'uniqueDonorsCount': uniqueDonors.length,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Отримати топ донорів для збору (не анонімних)
  Future<List<Map<String, dynamic>>> getTopDonors(String fundraisingId, {
    int limit = 5,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('donations')
          .where('fundraisingId', isEqualTo: fundraisingId)
          .where('isAnonymous', isEqualTo: false)
          .get();

      Map<String, Map<String, dynamic>> donorTotals = {};

      for (var doc in querySnapshot.docs) {
        final donation = DonationModel.fromMap(doc.data());

        if (donorTotals.containsKey(donation.donorId)) {
          donorTotals[donation.donorId]!['totalAmount'] += donation.amount;
          donorTotals[donation.donorId]!['donationCount'] += 1;
        } else {
          donorTotals[donation.donorId] = {
            'donorId': donation.donorId,
            'donorName': donation.donorName ?? 'Користувач',
            'totalAmount': donation.amount,
            'donationCount': 1,
          };
        }
      }

      var sortedDonors = donorTotals.values.toList();
      sortedDonors.sort(
            (a, b) =>
            (b['totalAmount'] as double).compareTo(a['totalAmount'] as double),
      );

      return sortedDonors.take(limit).toList();
    } catch (e) {
      rethrow;
    }
  }

  // Перевірити чи користувач вже донатив у цей збір
  Future<bool> hasUserDonated(String userId, String fundraisingId) async {
    try {
      final querySnapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .where('fundraisingId', isEqualTo: fundraisingId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Отримати загальну суму донатів користувача
  Future<double> getUserTotalDonations(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('donations')
          .where('donorId', isEqualTo: userId)
          .get();

      double total = 0;
      for (var doc in querySnapshot.docs) {
        final donation = DonationModel.fromMap(doc.data());
        total += donation.amount;
      }

      return total;
    } catch (e) {
      return 0;
    }
  }
}
