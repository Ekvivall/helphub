import 'package:cloud_firestore/cloud_firestore.dart';

class FAQItemModel {
  final String id;
  final String category;
  final String question;
  final String answer;
  final List<String> tags;
  final int order;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  FAQItemModel({
    required this.id,
    required this.category,
    required this.question,
    required this.answer,
    required this.tags,
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory FAQItemModel.fromMap(Map<String, dynamic> map, String id) {
    return FAQItemModel(
      id: id,
      category: map['category'] as String,
      question: map['question'] as String,
      answer: map['answer'] as String,
      tags: List<String>.from(map['tags'] ?? []),
      order: map['order'] ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'question': question,
      'answer': answer,
      'tags': tags,
      'order': order,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FAQItemModel copyWith({
    String? id,
    String? category,
    String? question,
    String? answer,
    List<String>? tags,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FAQItemModel(
      id: id ?? this.id,
      category: category ?? this.category,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      tags: tags ?? this.tags,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
