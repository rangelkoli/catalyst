class Habit {
  final String id;
  final String userId;
  final String desc;
  final int difficulty;
  final String whenWhere;
  final bool sharedWithFriends;

  Habit({
    required this.id,
    required this.userId,
    required this.desc,
    required this.difficulty,
    required this.whenWhere,
    this.sharedWithFriends = false,
  });

  factory Habit.fromMap(Map<String, dynamic> data, String id) => Habit(
    id: id,
    userId: data['userId'] ?? '',
    desc: data['desc'] ?? '',
    difficulty: data['difficulty'] ?? 0,
    whenWhere: data['whenWhere'] ?? '',
    sharedWithFriends: data['sharedWithFriends'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'desc': desc,
    'difficulty': difficulty,
    'whenWhere': whenWhere,
    'sharedWithFriends': sharedWithFriends,
  };
}
