import 'package:cloud_firestore/cloud_firestore.dart';

class FollowModel {
  final String id;
  final String followerId; //volunteer
  final String followedId; //organization
  final Timestamp timestamp;

  FollowModel({
    required this.id,
    required this.followerId,
    required this.followedId,
    required this.timestamp,
  });

  factory FollowModel.fromMap(String id, Map<String, dynamic> map) {
    return FollowModel(
      id: id,
      followerId: map['followerId'] as String,
      followedId: map['followedId'] as String,
      timestamp: map['timestamp'] as Timestamp,
    );
  }

  Map<String, dynamic>toMap(){
    return{
      'followerId': followerId,
      'followedId': followedId,
      'timestamp': timestamp
    };
  }
}
