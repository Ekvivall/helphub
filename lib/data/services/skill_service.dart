import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/models/category_chip_model.dart';

class SkillService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _skillsCollection =>
      _firestore.collection('skills');

  Future<List<CategoryChipModel>> fetchSkills() async {
    try {
      final querySnapshot = await _skillsCollection.orderBy('title').get();
      final skills = querySnapshot.docs.map((doc) {
        return CategoryChipModel.fromMap(doc.data());
      }).toList();
      return skills;
    } catch (e) {
      return [];
    }
  }

  Stream<List<CategoryChipModel>> fetchSkillsStream() {
    return _skillsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return CategoryChipModel.fromMap(doc.data());
      }).toList();
    });
  }

  Future<void> addSkill({
    required String title,
  }) async {
    try {
      final skillData = CategoryChipModel(title: title).toMap();
      await _skillsCollection.add(skillData);
    } catch (e) {
      rethrow;
    }
  }
}