import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:helphub/data/models/volunteer_model.dart';

import '../models/admin_statistics_model.dart';
import '../models/feedback_model.dart';
import '../models/organization_verification_model.dart';
import '../models/support_ticket_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<AdminStatisticsModel> getStatistics() async {
    try {
      final volunteerSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'volunteer')
          .get();
      final totalVolunteers = volunteerSnapshot.docs.length;
      final organizationsSnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'organization')
          .get();
      final totalOrganizations = organizationsSnapshot.docs.length;
      final eventsSnapshot = await _firestore.collection('events').get();
      final totalEvents = eventsSnapshot.docs.length;
      final projectsSnapshot = await _firestore.collection('projects').get();
      final totalProjects = projectsSnapshot.docs.length;
      final fundraisingsSnapshot = await _firestore
          .collection('fundraisings')
          .get();
      final totalFundraisings = fundraisingsSnapshot.docs.length;
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final activeUsersSnapshot = await _firestore
          .collection('users')
          .where('lastSignInAt', isGreaterThanOrEqualTo: thirtyDaysAgo)
          .get();
      final activeUsers = activeUsersSnapshot.docs.length;
      final firstDayOfMonth = DateTime(
        DateTime
            .now()
            .year,
        DateTime
            .now()
            .month,
        1,
      );
      final newUsersSnapshot = await _firestore
          .collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
          .get();
      final newUsersThisMonth = newUsersSnapshot.docs.length;
      final eventsByMonth = await _getEventsByMonth();
      final projectsByMonth = await _getProjectsByMonth();
      final topVolunteers = await _getTopVolunteers();
      return AdminStatisticsModel(
        totalVolunteers: totalVolunteers,
        totalOrganizations: totalOrganizations,
        totalEvents: totalEvents,
        totalProjects: totalProjects,
        totalFundraisings: totalFundraisings,
        activeUsers: activeUsers,
        newUsersThisMonth: newUsersThisMonth,
        eventsByMonth: eventsByMonth,
        projectsByMonth: projectsByMonth,
        topVolunteers: topVolunteers,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, int>> _getEventsByMonth() async {
    final Map<String, int> eventsByMonth = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final snapshot = await _firestore
          .collection('events')
          .where('date', isGreaterThanOrEqualTo: date)
          .where('date', isLessThan: nextMonth)
          .get();
      final monthKey = '${date.month.toString().padLeft(2, '0')}.${date.year}';
      eventsByMonth[monthKey] = snapshot.docs.length;
    }
    return eventsByMonth;
  }

  Future<Map<String, int>> _getProjectsByMonth() async {
    final Map<String, int> projectsByMonth = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final nextMonth = DateTime(now.year, now.month - i + 1, 1);
      final String startString = date.toIso8601String();
      final String endString = nextMonth.toIso8601String();
      final snapshot = await _firestore
          .collection('projects')
          .where('startDate', isGreaterThanOrEqualTo: startString)
          .where('startDate', isLessThan: endString)
          .get();
      final monthKey = '${date.month.toString().padLeft(2, '0')}.${date.year}';
      projectsByMonth[monthKey] = snapshot.docs.length;
    }
    return projectsByMonth;
  }

  Future<List<TopVolunteerModel>> _getTopVolunteers() async {
    final snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'volunteer')
        .orderBy('points', descending: true)
        .limit(10)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return TopVolunteerModel(
        uid: doc.id,
        name: data['fullName'] ?? data['displayName'] ?? 'Волонтер',
        photoUrl: data['photoUrl'],
        points: data['points'] ?? 0,
        projectsCount: data['projectsCount'] ?? 0,
        eventsCount: data['eventsCount'] ?? 0,
      );
    }).toList();
  }


  Stream<List<OrganizationVerificationModel>> getPendingVerifications() {
    return _firestore
        .collection('users')
        .where('role', isEqualTo: 'organization')
        .where('isVerification', isEqualTo: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<OrganizationVerificationModel> verifications = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        verifications.add(
          OrganizationVerificationModel(
            id: doc.id,
            organizationId: doc.id,
            organizationName: data['organizationName'] ?? 'Фонд',
            organizationPhotoUrl: data['photoUrl'],
            documents: List<String>.from(data['documents'] ?? []),
            status: VerificationStatus.pending,
            submittedAt:
            (data['createdAt'] as Timestamp?)?.toDate() ??
                DateTime.now(),
            email: data['email'] ?? '',
            phoneNumber: data['phoneNumber'],
          ),
        );
      }
      return verifications;
    });
  }

  Future<void> approveOrganization(String organizationId) async {
    try {
      await _firestore.collection('users').doc(organizationId).update({
        'isVerification': true,
        'verificationStatus': 'approved',
        'verifiedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error approving organization: $e');
      rethrow;
    }
  }

  Future<void> rejectOrganization(String organizationId, String reason) async {
    try {
      await _firestore.collection('users').doc(organizationId).update({
        'isVerification': false,
        'verificationStatus': 'rejected',
        'rejectedReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }


  Stream<List<SupportTicketModel>> getSupportTickets() {
    return _firestore
        .collection('supportTickets')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SupportTicketModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Future<void> respondToTicket(String ticketId,
      String response,
      String adminId,) async {
    try {
      await _firestore.collection('supportTickets').doc(ticketId).update({
        'adminResponse': response,
        'adminId': adminId,
        'status': SupportTicketStatus.resolved.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error responding to ticket: $e');
      rethrow;
    }
  }

  Future<void> updateTicketStatus(String ticketId,
      SupportTicketStatus status,) async {
    try {
      await _firestore.collection('supportTickets').doc(ticketId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }


  Stream<List<FeedbackModel>> getFeedback() {
    return _firestore.collection('feedback').orderBy(
        'timestamp', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) =>
          FeedbackModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> markFeedbackAdRead(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'status': FeedbackStatus.read.name
      });
    } catch (e) {
      print('Error making feedback as read: $e');
      rethrow;
    }
  }

  Future<void> processFeedback(String feedbackId, String adminNote) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).update({
        'status': FeedbackStatus.processed.name,
        'adminNote': adminNote
      });
    } catch (e) {
      rethrow;
    }
  }


  Future<List<VolunteerModel>> searchVolunteers(String query) async {
    try {
      final querySnapshot = await _firestore.collection('users').where(
          'role', isEqualTo: 'volunteer').get();
      final volunteers = querySnapshot.docs.map((doc) =>
          VolunteerModel.fromMap(doc.data())).where((volunteer) {
        final fullName = (volunteer.fullName ?? '').toLowerCase();
        final displayName = (volunteer.displayName ?? '').toLowerCase();
        final city = (volunteer.city ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return fullName.contains(searchLower) ||
            displayName.contains(searchLower) || city.contains(searchLower);
      }).toList();
      return volunteers;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addMedalToSeason(String seasonId, String medalType,
      File imageFile) async {
    try {
      final String storagePath = 'medals/$seasonId/$medalType.png';
      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/png'),
      );
    } catch(e){
      print('Error adding medal: $e');
      rethrow;
    }
  }
}
