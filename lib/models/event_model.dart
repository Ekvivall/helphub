import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/category_chip_model.dart';

class EventModel {
  final String? id;
  final String name;
  final String locationText;
  final GeoPoint? locationGeoPoint;
  final List<CategoryChipModel> categories;
  final DateTime date;
  final String startTime;
  final String duration;
  final String description;
  final String? photoUrl;
  final int maxParticipants;
  final String organizerId;
  final String organizerName;
  final List<String> participantIds;

  EventModel({
    this.id,
    required this.name,
    required this.locationText,
    this.locationGeoPoint,
    required this.categories,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.description,
    this.photoUrl,
    required this.maxParticipants,
    required this.organizerId,
    required this.organizerName,
    this.participantIds = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'locationText': locationText,
      'locationGeoPoint': locationGeoPoint,
      'categories': categories.map((e) => e.toMap()).toList(),
      'date': Timestamp.fromDate(date),
      'startTime': startTime,
      'duration': duration,
      'description': description,
      'photoUrl': photoUrl,
      'maxParticipants': maxParticipants,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'participantIds': participantIds,
    };
  }

  
  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      name: map['name'] as String,
      locationText: map['locationText'] as String,
      locationGeoPoint: map['locationGeoPoint'] as GeoPoint?,
      categories: (map['categories'] as List<dynamic>)
          .map((e) => CategoryChipModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      date: (map['date'] as Timestamp).toDate(),
      startTime: map['startTime'] as String,
      duration: map['duration'] as String,
      description: map['description'] as String,
      photoUrl: map['photoUrl'] as String?,
      maxParticipants: map['maxParticipants'] as int,
      organizerId: map['organizerId'] as String,
      organizerName: map['organizerName'] as String,
      participantIds: List<String>.from(map['participantIds'] as List<dynamic>),
    );
  }
}