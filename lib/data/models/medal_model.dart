import 'package:cloud_firestore/cloud_firestore.dart';

class MedalModel {
  final String id;
  final String seasonId; // "2025-03"
  final MedalType type; // gold, silver, bronze
  final int place; // 1-10
  final String iconPath;
  final DateTime awardedAt;
  final int groupNumber;
  final int totalParticipants;
  final int seasonPoints;

  MedalModel({
    required this.id,
    required this.seasonId,
    required this.type,
    required this.place,
    required this.iconPath,
    required this.awardedAt,
    required this.groupNumber,
    required this.totalParticipants,
    required this.seasonPoints,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seasonId': seasonId,
      'type': type.name,
      'place': place,
      'iconPath': iconPath,
      'awardedAt': Timestamp.fromDate(awardedAt),
      'groupNumber': groupNumber,
      'totalParticipants': totalParticipants,
      'seasonPoints': seasonPoints,
    };
  }

  factory MedalModel.fromMap(Map<String, dynamic> map) {
    return MedalModel(
      id: map['id'] as String,
      seasonId: map['seasonId'] as String,
      type: MedalType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => MedalType.bronze,
      ),
      place: map['place'] as int,
      iconPath: map['iconPath'] as String,
      awardedAt: (map['awardedAt'] as Timestamp).toDate(),
      groupNumber: map['groupNumber'] as int,
      totalParticipants: map['totalParticipants'] as int,
      seasonPoints: map['seasonPoints'] as int,
    );
  }

  String get seasonName {
    final parts = seasonId.split('-');
    if (parts.length != 2) return seasonId;
    final year = parts[0];
    final month = int.tryParse(parts[1]) ?? 1;
    final monthNames = [
      'Січень',
      'Лютий',
      'Березень',
      'Квітень',
      'Травень',
      'Червень',
      'Липень',
      'Серпень',
      'Вересень',
      'Жовтень',
      'Листопад',
      'Грудень',
    ];
    return '${monthNames[month - 1]} $year';
  }
}

enum MedalType {
  gold, // 1 місце
  silver, // 2-3 місця
  bronze, // 4-10 місця
}
