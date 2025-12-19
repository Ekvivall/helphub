class LevelModel {
  final int level;
  final int minPoints;
  final int maxPoints;
  final String title;
  final String description;
  final String framePath;
  final String avatarPath;

  LevelModel({
    required this.level,
    required this.minPoints,
    required this.maxPoints,
    required this.title,
    required this.description,
    required this.framePath,
    required this.avatarPath,
  });

  //Перевірка чи досяг цього рівня
  bool isUnlocked(int userPoints) => userPoints >= minPoints;

  // Прогрес до наступного рівня
  double getProgress(int userPoints) {
    if (userPoints >= maxPoints) return 1.0;
    if (userPoints < minPoints) return 0.0;
    final range = maxPoints - minPoints;
    final progress = userPoints - minPoints;
    return progress / range;
  }

  int getPointsToNext(int userPoints) {
    if (userPoints >= maxPoints) return 0;
    return maxPoints - userPoints;
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level,
      'minPoints': minPoints,
      'maxPoints': maxPoints,
      'title': title,
      'description': description,
      'framePath': framePath,
      'avatarPath': avatarPath,
    };
  }

  factory LevelModel.fromMap(Map<String, dynamic> map) {
    return LevelModel(
      level: map['level'] as int,
      minPoints: map['minPoints'] as int,
      maxPoints: map['maxPoints'] as int,
      title: map['title'] as String,
      description: map['description'] as String,
      framePath: map['framePath'] as String,
      avatarPath: map['avatarPath'] as String,
    );
  }
}
