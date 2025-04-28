import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'notification_helper.dart';
import 'firestore_service.dart';
import 'gemini_service.dart';
import '../models/habit.dart';

class HabitNotificationScheduler {
  final FirestoreService firestore;
  final GeminiService gemini;

  HabitNotificationScheduler({required this.firestore, required this.gemini});

  Future<void> scheduleAllHabitNotifications(String userApiKey) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final habits = await firestore.habitsStream(user.uid).first;
    int notifId = 0;
    for (final habit in habits) {
      if (habit.whenWhere.isEmpty) continue;
      final prompt =
          'Given the following habit cue: "${habit.whenWhere}", suggest the best time of day (in 24-hour format, e.g., 07:30 or 18:45) for a notification to maximize the chance of habit completion. Only return the time.';
      String? timeStr;
      try {
        timeStr = await gemini.generateText(prompt);
      } catch (e) {
        debugPrint('Gemini error: $e');
        continue;
      }
      if (timeStr == null) continue;
      final time = _parseTime24h(timeStr.trim());
      if (time == null) continue;
      await NotificationHelper.scheduleHabitNotification(
        id: notifId++,
        title: 'Habit Reminder',
        body: habit.desc,
        time24h: time,
      );
    }
  }

  String? _parseTime24h(String input) {
    final regex = RegExp(r'^(\d{1,2}):(\d{2})');
    final match = regex.firstMatch(input);
    if (match == null) return null;
    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}
