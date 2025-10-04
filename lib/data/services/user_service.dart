import 'package:cloud_firestore/cloud_firestore.dart';

import '../../data/models/base_profile_model.dart';
import '../../data/models/organization_model.dart';
import '../../data/models/volunteer_model.dart';

class UserService{
  Future<BaseProfileModel?> fetchUserProfile(String? userId) async {
    try {
      if (userId == null) return null;
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('users').doc(userId).get();
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
}