class Goal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> habitIds;
  final int progress;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.habitIds = const [],
    this.progress = 0,
  });

  factory Goal.fromMap(Map<String, dynamic> data, String id) => Goal(
    id: id,
    userId: data['userId'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    habitIds: List<String>.from(data['habitIds'] ?? []),
    progress: data['progress'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'description': description,
    'habitIds': habitIds,
    'progress': progress,
  };
}
