import 'package:cloud_firestore/cloud_firestore.dart';

class Achievement {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime achievedAt;

  Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.achievedAt,
  });

  factory Achievement.fromMap(Map<String, dynamic> data, String id) =>
      Achievement(
        id: id,
        userId: data['userId'] ?? '',
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        achievedAt:
            (data['achievedAt'] is Timestamp)
                ? (data['achievedAt'] as Timestamp).toDate()
                : DateTime.tryParse(data['achievedAt'].toString()) ??
                    DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'title': title,
    'description': description,
    'achievedAt': achievedAt,
  };
}
