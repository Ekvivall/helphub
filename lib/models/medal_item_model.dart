class MedalItemModel {
  String? imagePath;
  String? title;

  MedalItemModel({this.imagePath, this.title});

  Map<String, dynamic> toMap() {
    return {'imagePath': imagePath, 'title': title};
  }

  factory MedalItemModel.fromMap(Map<String, dynamic> map) {
    return MedalItemModel(
      imagePath: map['imagePath'] as String?,
      title: map['title'] as String?,
    );
  }
}