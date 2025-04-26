import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressLog {
  final String id;
  final String userId;
  final String habitId;
  final DateTime date;
  final int pointsEarned;

  ProgressLog({
    required this.id,
    required this.userId,
    required this.habitId,
    required this.date,
    this.pointsEarned = 0,
  });

  factory ProgressLog.fromMap(Map<String, dynamic> data, String id) =>
      ProgressLog(
        id: id,
        userId: data['userId'] ?? '',
        habitId: data['habitId'] ?? '',
        date: (data['date'] as Timestamp).toDate(),
        pointsEarned: data['pointsEarned'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'habitId': habitId,
    'date': date,
    'pointsEarned': pointsEarned,
  };
}
