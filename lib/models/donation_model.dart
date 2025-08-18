// lib/models/donation_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DonationModel {
  final String? id;
  final String fundraisingId;
  final String donorId;
  final String? donorName;
  final double amount;
  final DateTime timestamp;
  final bool isAnonymous;

  DonationModel({
    this.id,
    required this.fundraisingId,
    required this.donorId,
    this.donorName,
    required this.amount,
    required this.timestamp,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fundraisingId': fundraisingId,
      'donorId': donorId,
      'donorName': donorName,
      'amount': amount,
      'timestamp': Timestamp.fromDate(timestamp),
      'isAnonymous': isAnonymous,
    };
  }

  factory DonationModel.fromMap(Map<String, dynamic> map) {
    return DonationModel(
      id: map['id'] as String?,
      fundraisingId: map['fundraisingId'] as String,
      donorId: map['donorId'] as String,
      donorName: map['donorName'] as String?,
      amount: (map['amount'] as num).toDouble(),
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isAnonymous: map['isAnonymous'] as bool? ?? false,
    );
  }

  DonationModel copyWith({
    String? id,
    String? fundraisingId,
    String? donorId,
    String? donorName,
    double? amount,
    DateTime? timestamp,
    bool? isAnonymous,
  }) {
    return DonationModel(
      id: id ?? this.id,
      fundraisingId: fundraisingId ?? this.fundraisingId,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      isAnonymous: isAnonymous ?? this.isAnonymous,
    );
  }
}