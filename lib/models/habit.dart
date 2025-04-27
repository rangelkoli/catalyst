class Habit {
  final String id;
  final String userId;
  final String desc;
  final int difficulty;
  final String whenWhere;

  Habit({
    required this.id,
    required this.userId,
    required this.desc,
    required this.difficulty,
    required this.whenWhere,
  });

  factory Habit.fromMap(Map<String, dynamic> data, String id) => Habit(
    id: id,
    userId: data['userId'] ?? '',
    desc: data['desc'] ?? '',
    difficulty: data['difficulty'] ?? 0,
    whenWhere: data['whenWhere'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'desc': desc,
    'difficulty': difficulty,
    'whenWhere': whenWhere,
  };
}
