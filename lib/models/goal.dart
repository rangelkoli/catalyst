import 'package:cloud_firestore/cloud_firestore.dart';

class Goal {
  final String id;
  final String userId;
  final String title;
  final String description;
  final List<String> habitIds;
  final int progress;
  final List<String> tags;
  final int streak;
  final DateTime? targetDate;

  Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    this.habitIds = const [],
    this.progress = 0,
    this.tags = const [],
    this.streak = 0,
    this.targetDate,
  });

  factory Goal.fromMap(Map<String, dynamic> data, String id) => Goal(
    id: id,
    userId: data['userId'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    habitIds: List<String>.from(data['habitIds'] ?? []),
    progress: data['progress'] ?? 0,
    tags: List<String>.from(data['tags'] ?? []),
    streak: data['streak'] ?? 0,
    targetDate:
        data['targetDate'] == null
            ? null
            : (data['targetDate'] is DateTime)
            ? data['targetDate']
            : (data['targetDate'] is Timestamp)
            ? (data['targetDate'] as Timestamp).toDate()
            : DateTime.tryParse(data['targetDate'].toString()),
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'description': description,
    'habitIds': habitIds,
    'progress': progress,
    'tags': tags,
    'streak': streak,
    if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
  };
}
