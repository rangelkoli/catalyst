import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final int target;
  final int progress;

  Challenge({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.startDate,
    required this.endDate,
    required this.target,
    this.progress = 0,
  });

  factory Challenge.fromMap(Map<String, dynamic> data, String id) => Challenge(
    id: id,
    userId: data['userId'] ?? '',
    title: data['title'] ?? '',
    description: data['description'] ?? '',
    startDate: (data['startDate'] as Timestamp).toDate(),
    endDate: (data['endDate'] as Timestamp).toDate(),
    target: data['target'] ?? 0,
    progress: data['progress'] ?? 0,
  );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'description': description,
    'startDate': startDate,
    'endDate': endDate,
    'target': target,
    'progress': progress,
  };
}
