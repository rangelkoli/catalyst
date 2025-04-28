import 'package:flutter/material.dart';
import 'services/firestore_service.dart';
import 'models/habit.dart';
import 'widgets/habit_completion_tile.dart';

class FriendHabitsScreen extends StatelessWidget {
  final String friendUid;
  const FriendHabitsScreen({super.key, required this.friendUid});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Shared Habits')),
      body: StreamBuilder<List<Habit>>(
        stream: firestore.sharedHabitsStream(friendUid),
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final habits = snap.data!;
          if (habits.isEmpty)
            return const Center(child: Text('No shared habits.'));
          return ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, i) {
              final habit = habits[i];
              return HabitCompletionTile(
                habit: habit,
                firestore: firestore,
                userId: friendUid,
                onEdit: null, // Friends can't edit
              );
            },
          );
        },
      ),
    );
  }
}
