class Habit {
  final String id;
  final String userId;
  final String goalId;
  final String name;
  final int points;
  final int streak;
  final int totalCompletions;

  Habit({
    required this.id,
    required this.userId,
    required this.goalId,
    required this.name,
    this.points = 0,
    this.streak = 0,
    this.totalCompletions = 0,
  });

  factory Habit.fromMap(Map<String, dynamic> data, String id) => Habit(
    id: id,
    userId: data['userId'] ?? '',
    goalId: data['goalId'] ?? '',
    name: data['name'] ?? '',
    points: data['points'] ?? 0,
    streak: data['streak'] ?? 0,
    totalCompletions: data['totalCompletions'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'goalId': goalId,
    'name': name,
    'points': points,
    'streak': streak,
    'totalCompletions': totalCompletions,
  };
}
