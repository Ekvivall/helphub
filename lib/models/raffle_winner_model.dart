import 'package:cloud_firestore/cloud_firestore.dart';

class RaffleWinnerModel {
  final String donorId;
  final String donorName;
  final String prize;
  final int ticketsWon;
  final Timestamp timestamp;

  RaffleWinnerModel({
    required this.donorId,
    required this.donorName,
    required this.prize,
    required this.ticketsWon,
    required this.timestamp,
  });

  factory RaffleWinnerModel.fromMap(Map<String, dynamic> map) {
    return RaffleWinnerModel(
      donorId: map['donorId'] as String,
      donorName: map['donorName'] as String,
      prize: map['prize'] as String,
      ticketsWon: map['ticketsWon'] as int,
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'prize': prize,
      'ticketsWon': ticketsWon,
      'timestamp': timestamp,
    };
  }
}