class TrustBadgeModel {
  String? imagePath;
  String? title;

  TrustBadgeModel({this.imagePath, this.title});

  Map<String, dynamic> toMap() {
    return {'imagePath': imagePath, 'title': title};
  }

  factory TrustBadgeModel.fromMap(Map<String, dynamic> map) {
    return TrustBadgeModel(
      imagePath: map['imagePath'] as String?,
      title: map['title'] as String?,
    );
  }
}