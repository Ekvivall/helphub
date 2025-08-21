class OrganizerFeedbackModel {
  final String participantId;
  final String participantName;
  final String? feedback;
  final int? rating; // 1-5 зірок
  final bool isAnonymous;

  OrganizerFeedbackModel({
    required this.participantId,
    required this.participantName,
    this.feedback,
    this.rating,
    this.isAnonymous = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'participantName': isAnonymous ? 'Анонімний учасник' : participantName,
      'feedback': feedback,
      'rating': rating,
      'isAnonymous': isAnonymous,
    };
  }

  factory OrganizerFeedbackModel.fromMap(Map<String, dynamic> map) {
    return OrganizerFeedbackModel(
      participantId: map['participantId'] as String,
      participantName: map['participantName'] as String,
      feedback: map['feedback'] as String?,
      rating: map['rating'] as int?,
      isAnonymous: map['isAnonymous'] as bool? ?? false,
    );
  }
}