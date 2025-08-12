import 'package:helphub/models/category_chip_model.dart';

class FundraisingModel {
  final String? id;
  final String? title;
  final String? description;
  final double? targetAmount;
  final double? currentAmount;
  final List<CategoryChipModel>? categories;
  final String? organizationId;
  final String? organizationName;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? timestamp;
  final List<String>? documentUrls;
  final String? photoUrl;
  final List<String>? donorIds;
  final String? bankAccountIban;
  final String? bankLink;
  final bool? isUrgent;
  final List<String>?
  relatedApplicationIds; // ID заявок, які входять в цей збір

  FundraisingModel({
    this.id,
    this.title,
    this.description,
    this.targetAmount,
    this.currentAmount = 0.0,
    this.categories,
    this.organizationId,
    this.organizationName,
    this.startDate,
    this.endDate,
    this.timestamp,
    this.documentUrls,
    this.photoUrl,
    this.donorIds,
    this.bankAccountIban,
    this.bankLink,
    this.isUrgent = false,
    this.relatedApplicationIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount ?? 0.0,
      'categories': categories?.map((c) => c.toMap()).toList(),
      'organizationId': organizationId,
      'organizationName': organizationName,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'timestamp': timestamp?.toIso8601String(),
      'documentUrls': documentUrls,
      'photoUrl': photoUrl,
      'donorIds': donorIds ?? [],
      'bankAccountIban': bankAccountIban,
      'bankLink': bankLink,
      'isUrgent': isUrgent,
      'relatedApplicationIds': relatedApplicationIds ?? [],
    };
  }

  factory FundraisingModel.fromMap(Map<String, dynamic> map) {
    return FundraisingModel(
      id: map['id'] as String?,
      title: map['title'] as String?,
      description: map['description'] as String?,
      targetAmount: (map['targetAmount'] as num?)?.toDouble(),
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      categories: (map['categories'] as List<dynamic>?)
          ?.map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      organizationId: map['organizationId'] as String?,
      organizationName: map['organizationName'] as String?,
      startDate: map['startDate'] != null
          ? DateTime.tryParse(map['startDate'] as String)
          : null,
      endDate: map['endDate'] != null
          ? DateTime.tryParse(map['endDate'] as String)
          : null,
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String)
          : null,
      documentUrls: (map['documentUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      photoUrl: map['photoUrl'] as String?,
      donorIds:
          (map['donorIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      bankAccountIban: map['bankAccountIban'] as String?,
      bankLink: map['bankLink'] as String?,
      isUrgent: map['isUrgent'] as bool? ?? false,
      relatedApplicationIds:
          (map['relatedApplicationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  FundraisingModel copyWith({
    String? id,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    List<CategoryChipModel>? categories,
    String? organizationId,
    String? organizationName,
    String? city,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? timestamp,
    List<String>? documentUrls,
    String? photoUrl,
    List<String>? donorIds,
    String? bankAccountIban,
    String? bankLink,
    bool? isUrgent,
    List<String>? relatedApplicationIds,
  }) {
    return FundraisingModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      categories: categories ?? this.categories,
      organizationId: organizationId ?? this.organizationId,
      organizationName: organizationName ?? this.organizationName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      timestamp: timestamp ?? this.timestamp,
      documentUrls: documentUrls ?? this.documentUrls,
      photoUrl: photoUrl ?? this.photoUrl,
      donorIds: donorIds ?? this.donorIds,
      bankAccountIban: bankAccountIban ?? this.bankAccountIban,
      bankLink: bankLink ?? this.bankLink,
      isUrgent: isUrgent ?? this.isUrgent,
      relatedApplicationIds:
          relatedApplicationIds ?? this.relatedApplicationIds,
    );
  }
}
