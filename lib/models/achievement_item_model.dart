class AchievementItemModel {
  String? imagePath;
  String? title;

  AchievementItemModel({this.imagePath, this.title});

  Map<String, dynamic> toMap() {
    return {'imagePath': imagePath, 'title': title};
  }

  factory AchievementItemModel.fromMap(Map<String, dynamic> map) {
    return AchievementItemModel(
      imagePath: map['imagePath'] as String?,
      title: map['title'] as String?,
    );
  }
}
