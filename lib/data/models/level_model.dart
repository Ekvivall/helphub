
enum PointAction{
  eventParticipation(10, 'Участь у події'),
  //eventCompletionWithReport(5, 'Звіт про подію'),
  projectParticipation(15, 'Участь у проєкті'),
  taskCompletion(10, 'Виконання завдання'),
  applicationApproved(3, 'Схвалена заявка'),
  eventOrganization(20, 'Організація події'),
  projectCreation(25, 'Створення проєкту'),
  reportPublication(10, 'Публікація звіту'),
  organizerFeedback(5, 'Відгук організатору'),
  achievementUnlocked(5, 'Отримання досягнення'),
  donation(0, 'Донат'), // Залежить від суми
  friendAdded(2, 'Додавання друга');

  final int points;
  final String description;

  const PointAction(this.points, this.description);

  // 1 бал за кожні 100 грн
  static int getDonationPoints(double amount){
    return (amount / 100).floor();
  }
}

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
