import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:helphub/models/category_chip_model.dart';

class EventModel {
  final String? id;
  final String name;
  final String locationText;
  final GeoPoint? locationGeoPoint;
  final List<CategoryChipModel> categories;
  final DateTime date;
  final String duration;
  final String description;
  final String? photoUrl;
  final int maxParticipants;
  final String organizerId;
  final String organizerName;
  final String city;
  final List<String> participantIds;
  final String? reportId;

  EventModel({
    this.id,
    required this.name,
    required this.locationText,
    this.locationGeoPoint,
    required this.categories,
    required this.date,
    required this.duration,
    required this.description,
    this.photoUrl,
    required this.maxParticipants,
    required this.organizerId,
    required this.organizerName,
    required this.city,
    this.participantIds = const [],
    this.reportId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'locationText': locationText,
      'locationGeoPoint': locationGeoPoint,
      'categories': categories.map((e) => e.toMap()).toList(),
      'date': Timestamp.fromDate(date),
      'duration': duration,
      'description': description,
      'photoUrl': photoUrl,
      'maxParticipants': maxParticipants,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'city': city,
      'participantIds': participantIds,
      'reportId': reportId,
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
      duration: map['duration'] as String,
      description: map['description'] as String,
      photoUrl: map['photoUrl'] as String?,
      maxParticipants: map['maxParticipants'] as int,
      organizerId: map['organizerId'] as String,
      organizerName: map['organizerName'] as String,
      city: map['city'] as String,
      participantIds: List<String>.from(map['participantIds'] as List<dynamic>),
      reportId: map['reportId'] as String?,
    );
  }

  EventModel copyWith({
    String? id,
    String? name,
    String? locationText,
    GeoPoint? locationGeoPoint,
    List<CategoryChipModel>? categories,
    DateTime? date,
    String? duration,
    String? description,
    String? photoUrl,
    int? maxParticipants,
    String? organizerId,
    String? organizerName,
    String? city,
    List<String>? participantIds,
    String? reportId,
  }) {
    return EventModel(
      id: id ?? this.id,
      name: name ?? this.name,
      locationText: locationText ?? this.locationText,
      locationGeoPoint: locationGeoPoint ?? this.locationGeoPoint,
      categories: categories ?? this.categories,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      city: city ?? this.city,
      participantIds: participantIds ?? this.participantIds,
      reportId: reportId ?? this.reportId,
    );
  }
}
