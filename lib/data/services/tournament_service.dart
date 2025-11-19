import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/models/medal_model.dart';

class TournamentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String getCurrentSeasonId() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Stream<List<TournamentUser>> getUserGroupLeaderboard(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().asyncExpand((
      userDoc,
    ) async* {
      if (!userDoc.exists) {
        yield [];
        return;
      }
      final userData = userDoc.data();
      final groupId = userData?['currentGroupId'] as String?;
      final seasonId = userData?['currentSeasonId'] as String?;
      if (groupId == null || seasonId == null) {
        yield [];
        return;
      }

      // Отримання групи
      final groupDoc = await _firestore
          .collection('tournamentSeasons')
          .doc(seasonId)
          .collection('groups')
          .doc(groupId)
          .get();

      if (!groupDoc.exists) {
        yield [];
        return;
      }
      final groupData = groupDoc.data();
      final userIds = List<String>.from(groupData?['userIds'] ?? []);
      // Отримання всіх користувачів групи
      final users = <TournamentUser>[];
      for (final uid in userIds) {
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final data = doc.data();
          users.add(
            TournamentUser(
              uid: uid,
              displayName:
                  data?['displayName'] ?? data?['fullName'] ?? 'Волонтер',
              photoUrl: data?['photoUrl'],
              frame: data?['frame'],
              seasonPoints: data?['seasonPoints'] ?? 0,
            ),
          );
        }
      }
      users.sort((a, b) => b.seasonPoints.compareTo(a.seasonPoints));
      yield users;
    });
  }

  Future<int?> getUserPlaceInGroup(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return null;
      final userData = userDoc.data();
      final groupId = userData?['currentGroupId'] as String?;
      final seasonId = userData?['currentSeasonId'] as String?;
      final userPoints = userData?['seasonPoints'] ?? 0;
      if (groupId == null || seasonId == null) return null;
      final groupDoc = await _firestore
          .collection('tournamentSeasons')
          .doc(seasonId)
          .collection('groups')
          .doc(groupId)
          .get();
      if (!groupDoc.exists) return null;
      final groupData = groupDoc.data();
      final userIds = List<String>.from(groupData?['userIds'] ?? []);
      // скільки користувачів має більше балів
      int place = 1;
      for (final uid in userIds) {
        if (uid == userId) continue;
        final doc = await _firestore.collection('users').doc(uid).get();
        if (doc.exists) {
          final points = doc.data()?['seasonPoints'] ?? 0;
          if (points > userPoints) {
            place++;
          }
        }
      }
      return place;
    } catch (e) {
      print('Error getting user place: $e');
      return null;
    }
  }

  DateTime getSeasonEndDate() {
    final now = DateTime.now();
    // Останній день поточного місяця
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }

  Stream<List<MedalModel>> getUserMedals(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      final medalsData = data?['medals'] as List?;
      if (medalsData == null) return [];
      return medalsData
          .map((m) => MedalModel.fromMap(m as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.awardedAt.compareTo(a.awardedAt));
    });
  }

  Future<bool> isUserInTop10(String userId) async {
    final place = await getUserPlaceInGroup(userId);
    return place != null && place <= 10;
  }
}

class TournamentUser {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final String? frame;
  final int seasonPoints;

  TournamentUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.frame,
    required this.seasonPoints,
  });
}
