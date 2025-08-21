class ParticipantFeedbackModel {
  final String participantId;
  final String participantName;
  final String? feedback;

  ParticipantFeedbackModel({
    required this.participantId,
    required this.participantName,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      'feedback': feedback,
    };
  }

  factory ParticipantFeedbackModel.fromMap(Map<String, dynamic> map) {
    return ParticipantFeedbackModel(
      participantId: map['participantId'] as String,
      participantName: map['participantName'] as String,
      feedback: map['feedback'] as String?,
    );
  }
}