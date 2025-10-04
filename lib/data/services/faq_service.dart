import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/data/models/faq_item_model.dart';

class FAQService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'faq';

  Future<List<FAQItemModel>> getFAQItems() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .orderBy('order', descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => FAQItemModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error fetching FAQ items: $e');
      rethrow;
    }
  }

  Stream<List<FAQItemModel>> getFAQItemsStream() {
    return _firestore
        .collection(_collectionName)
        .orderBy('order', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FAQItemModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // для адміністраторів
  Future<String> addFAQItem(FAQItemModel item) async {
    try {
      final docRef = await _firestore.collection(_collectionName).add(
          item.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding FAQ item: $e');
      rethrow;
    }
  }

  Future<void> updateFAQItem(String id, FAQItemModel item) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update(item.toMap());
    } catch (e) {
      print('Error updating FAQ item: $e');
      rethrow;
    }
  }

  Future<void> deleteFAQItem(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();
    } catch (e) {
      print('Error deleting FAQ item: $e');
      rethrow;
    }
  }

  Future<List<FAQItemModel>> searchFAQItems(String query) async {
    try {
      if (query.isEmpty) {
        return await getFAQItems();
      }

      final allItems = await getFAQItems();
      final queryLowerCase = query.toLowerCase();
      return allItems.where((item) {
        return item.question.toLowerCase().contains(queryLowerCase) ||
            item.answer.toLowerCase().contains(queryLowerCase) ||
            item.category.toLowerCase().contains(queryLowerCase) ||
            item.tags.any((tag) => tag.toLowerCase().contains(queryLowerCase));
      }).toList();
    } catch (e) {
      print('Error searching FAQ items: $e');
      rethrow;
    }
  }

  Future<List<FAQItemModel>> getFAQItemsByCategory(String category) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collectionName)
          .where('category', isEqualTo: category)
          .orderBy('order', descending: false)
          .get();

      return querySnapshot.docs.map((doc) =>
          FAQItemModel.fromMap(doc.data(), doc.id)).toList();
    } catch (e) {
      print('Error fetching FAQ items by category: $e');
      rethrow;
    }
  }

  Future<List<String>> getFAQCategories() async {
    try {
      final allItems = await getFAQItems();
      final categories = allItems.map((item) => item.category).toSet().toList();
      return categories;
    }  catch(e){
      print('Error fetching FAQ categories: $e');
      rethrow;
    }
  }
}
