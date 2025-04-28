import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/habit.dart';
import '../models/reward.dart';
import 'dart:async';

class UserPointsWidget extends StatelessWidget {
  const UserPointsWidget({super.key});

  Stream<int> _pointsStream(String userId) async* {
    final firestore = FirestoreService();
    await for (final habits in firestore.habitsStream(userId)) {
      // For each habit, listen to completions
      final completionsFutures = habits.map(
        (habit) =>
            firestore
                .habitCompletionsStream(userId: userId, habitId: habit.id)
                .first,
      );
      final completionsList = await Future.wait(completionsFutures);
      int totalPoints = 0;
      for (int i = 0; i < habits.length; i++) {
        final habit = habits[i];
        final completions = completionsList[i];
        totalPoints +=
            (completions.length * (habit.difficulty > 0 ? habit.difficulty : 1))
                .toInt();
      }
      // Listen to rewards
      final rewards = await firestore.rewardsStream(userId).first;
      final spent = rewards.fold<int>(
        0,
        (sum, r) =>
            sum +
            ((r.cost > 0 ? r.cost : 0) *
                (r.redeemedCount > 0 ? r.redeemedCount : 0)),
      );
      yield (totalPoints - spent).toInt();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    return StreamBuilder<int>(
      stream: _pointsStream(user.uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.only(right: 16),
            child: SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                snap.data.toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
