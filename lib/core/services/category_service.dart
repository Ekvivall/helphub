import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/category_chip_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Метод для отримання всіх категорій сфер діяльності з Firestore
  Future<List<CategoryChipModel>> fetchCategories() async {
    try {
      final QuerySnapshot querySnapshot = await _firestore.collection(
          'categories').orderBy('title').get();
      final List<CategoryChipModel> categories = querySnapshot.docs.map((doc){
        return CategoryChipModel.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
      return categories;
    } catch(e){
      return [];
    }
  }
}