import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/goal.dart';
import 'models/habit.dart';
import 'widgets/user_points_widget.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: const [UserPointsWidget()],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your Goals',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Goal>>(
              stream: firestore.goalsStream(user.uid),
              builder: (context, goalSnap) {
                if (!goalSnap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final goals = goalSnap.data!;
                if (goals.isEmpty)
                  return const Center(child: Text('No goals yet.'));
                return ListView.builder(
                  itemCount: goals.length,
                  itemBuilder: (context, i) {
                    final goal = goals[i];
                    return ListTile(
                      title: Text(goal.title),
                      subtitle: Text(goal.description),
                      trailing: Text('Progress: ${goal.progress}%'),
                    );
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Your Habits',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Habit>>(
              stream: firestore.habitsStream(user.uid),
              builder: (context, habitSnap) {
                if (!habitSnap.hasData)
                  return const Center(child: CircularProgressIndicator());
                final habits = habitSnap.data!;
                if (habits.isEmpty)
                  return const Center(child: Text('No habits yet.'));
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemCount: habits.length,
                  itemBuilder: (context, i) {
                    final habit = habits[i];
                    return _MinimalHabitBlock(
                      habit: habit,
                      onComplete: (bool completed) async {
                        if (completed) {
                          await firestore.completeHabit(
                            userId: user.uid,
                            habitId: habit.id,
                            date: DateTime(2025, 4, 28), // Use current date
                          );
                        } else {
                          await firestore.uncompleteHabit(
                            userId: user.uid,
                            habitId: habit.id,
                            date: DateTime(2025, 4, 28), // Use current date
                          );
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalHabitBlock extends StatefulWidget {
  final Habit habit;
  final Future<void> Function(bool completed) onComplete;
  const _MinimalHabitBlock({required this.habit, required this.onComplete});

  @override
  State<_MinimalHabitBlock> createState() => _MinimalHabitBlockState();
}

class _MinimalHabitBlockState extends State<_MinimalHabitBlock> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();
    final firestore = FirestoreService();
    final today = DateTime.now();
    final todayStr =
        '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return StreamBuilder<List<String>>(
      stream: firestore.habitCompletionsStream(
        userId: user.uid,
        habitId: widget.habit.id,
      ),
      builder: (context, snap) {
        final completions = snap.data ?? [];
        final completed = completions.contains(todayStr);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: completed ? Colors.green.shade400 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(16),
            boxShadow:
                completed
                    ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => widget.onComplete(!completed),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                child: Row(
                  children: [
                    Icon(
                      completed
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: completed ? Colors.white : Colors.grey.shade600,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.habit.desc,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: completed ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (completed)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: Text(
                          'Undo',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
