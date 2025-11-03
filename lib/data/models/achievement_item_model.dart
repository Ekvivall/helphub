
class AchievementModel {
  final String id;
  final String title;
  final String description;
  final String iconPath;
  final bool isSecret;
  final int order;

  AchievementModel({
    required this.id,
    required this.title,
    required this.description,
    required this.iconPath,
    required this.isSecret,
    required this.order,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'iconPath': iconPath,
      'isSecret': isSecret,
      'order': order,
    };
  }

  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      iconPath: map['iconPath'] as String,
      isSecret: map['isSecret'] as bool,
      order: map['order'] as int,
    );
  }

  AchievementModel copyWith({
    String? id,
    String? title,
    String? description,
    String? iconPath,
    bool? isSecret,
    int? order,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      isSecret: isSecret ?? this.isSecret,
      order: order ?? this.order,
    );
  }
}