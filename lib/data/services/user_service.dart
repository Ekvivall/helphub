import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/volunteer_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<BaseProfileModel?> fetchUserProfile(String? userId) async {
    try {
      if (userId == null) return null;
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data();
        final roleString = data?['role'] as String?;
        if (roleString == UserRole.volunteer.name) {
          return VolunteerModel.fromMap(doc.data()!);
        } else {
          return OrganizationModel.fromMap(doc.data()!);
        }
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateSelectedFrame(String userId, String framePath) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'frame': framePath,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfilePhoto(String userId, String photoUrl) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'photoUrl': photoUrl,
      });
    } catch (e) {
      rethrow;
    }
  }
}
