import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/category_chip_model.dart';

class FundraiserApplicationModel {
  final String id;
  final String volunteerId;
  final String organizationId;
  final String title;
  final List<CategoryChipModel> categories;
  final String description;
  final double requiredAmount;
  final Timestamp deadline;
  final List<String>? supportingDocuments;
  final String contactInfo;
  final String status;
  final Timestamp timestamp;

  FundraiserApplicationModel({
    required this.id,
    required this.volunteerId,
    required this.organizationId,
    required this.title,
    required this.categories,
    required this.description,
    required this.requiredAmount,
    required this.deadline,
    this.supportingDocuments,
    required this.contactInfo,
    this.status = 'pending',
    required this.timestamp,
  });

  factory FundraiserApplicationModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return FundraiserApplicationModel(
      id: id,
      volunteerId: map['volunteerId'] as String,
      organizationId:map['organizationId'] as String,
      title: map['title'] as String,
      categories:
          (map['categories'] as List<dynamic>?)
              ?.map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      description: map['description'] as String,
      requiredAmount: (map['requiredAmount'] as num).toDouble(),
      deadline: map['deadline'] as Timestamp,
      supportingDocuments:
          (map['supportingDocuments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      contactInfo: map['contactInfo'] as String,
      status: map['status'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteerId': volunteerId,
      'organizationId':organizationId,
      'title': title,
      'categories': categories.map((e) => e.toMap()).toList(),
      'description': description,
      'requiredAmount': requiredAmount,
      'deadline': deadline,
      'supportingDocuments': supportingDocuments,
      'contactInfo': contactInfo,
      'status': status,
      'timestamp': timestamp,
    };
  }
}
