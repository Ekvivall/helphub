import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/category_chip_model.dart';
import 'package:helphub/models/raffle_winner_model.dart';

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
  final String? privatBankCard;
  final String? monoBankCard;
  final bool? isUrgent;
  final List<String>?
  relatedApplicationIds; // ID заявок, які входять в цей збір
  final bool hasRaffle;
  double? ticketPrice;
  List<String>? prizes;
  final String? status;
  final List<RaffleWinnerModel>? raffleWinners;


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
    this.privatBankCard,
    this.monoBankCard,
    this.isUrgent = false,
    this.relatedApplicationIds,
    this.hasRaffle = false,
    this.ticketPrice,
    this.prizes,
    this.status,
    this.raffleWinners,

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
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'timestamp': timestamp?.toIso8601String(),
      'documentUrls': documentUrls,
      'photoUrl': photoUrl,
      'donorIds': donorIds ?? [],
      'privatBankCard': privatBankCard,
      'monoBankCard': monoBankCard,
      'isUrgent': isUrgent,
      'relatedApplicationIds': relatedApplicationIds ?? [],
      'hasRaffle': hasRaffle,
      'ticketPrice': ticketPrice,
      'prizes': prizes ?? [],
      'status': status,
      'raffleWinners': raffleWinners?.map((e) => e.toMap()).toList(),

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
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      endDate: (map['endDate'] as Timestamp?)?.toDate(),
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
      privatBankCard: map['privatBankCard'] as String?,
      monoBankCard: map['monoBankCard'] as String?,
      isUrgent: map['isUrgent'] as bool? ?? false,
      relatedApplicationIds:
          (map['relatedApplicationIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hasRaffle: map['hasRaffle'] ?? false,
      ticketPrice: map['ticketPrice'] != null
          ? (map['ticketPrice']).toDouble()
          : null,
      prizes: (map['prizes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
          [],
      status: map['status'] as String?,
      raffleWinners: (map['raffleWinners'] as List<dynamic>?)
          ?.map((e) => RaffleWinnerModel.fromMap(e as Map<String, dynamic>))
          .toList(),
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
    String? privatBankCard,
    String? monoBankCard,
    bool? isUrgent,
    List<String>? relatedApplicationIds,
    bool? hasRaffle,
    double? ticketPrice,
    List<String>? prizes,
    String? status,
    List<RaffleWinnerModel>? raffleWinners
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
      privatBankCard: privatBankCard ?? this.privatBankCard,
      monoBankCard: monoBankCard ?? this.monoBankCard,
      isUrgent: isUrgent ?? this.isUrgent,
      relatedApplicationIds:
          relatedApplicationIds ?? this.relatedApplicationIds,
      hasRaffle: hasRaffle ?? this.hasRaffle,
      ticketPrice: ticketPrice ?? this.ticketPrice,
      prizes: prizes ?? this.prizes,
      status: status ?? this.status,
      raffleWinners: raffleWinners ?? this.raffleWinners,
    );

  }
}
