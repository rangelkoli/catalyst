import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/habit.dart';
import 'models/goal.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _nameController = TextEditingController();
  String? _selectedGoalId;

  void _addHabit(List<Goal> goals) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _selectedGoalId == null) return;
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      goalId: _selectedGoalId!,
      name: _nameController.text.trim(),
    );
    await _firestore.addHabit(habit);
    _nameController.clear();
    Navigator.of(context).pop();
  }

  void _showAddHabitDialog(List<Goal> goals) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Habit Name'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGoalId,
                  items:
                      goals
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.title),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedGoalId = v),
                  decoration: const InputDecoration(labelText: 'Linked Goal'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => _addHabit(goals),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditHabitDialog(Habit habit, List<Goal> goals) {
    _nameController.text = habit.name;
    _selectedGoalId = habit.goalId;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Habit Name'),
                ),
                DropdownButtonFormField<String>(
                  value: _selectedGoalId,
                  items:
                      goals
                          .map(
                            (g) => DropdownMenuItem(
                              value: g.id,
                              child: Text(g.title),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => _selectedGoalId = v),
                  decoration: const InputDecoration(labelText: 'Linked Goal'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final updatedHabit = Habit(
                    id: habit.id,
                    userId: habit.userId,
                    goalId: _selectedGoalId!,
                    name: _nameController.text.trim(),
                    points: habit.points,
                    streak: habit.streak,
                    totalCompletions: habit.totalCompletions,
                  );
                  await _firestore.updateHabit(updatedHabit);
                  _nameController.clear();
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    return Scaffold(
      appBar: AppBar(title: const Text('Habits')),
      body: StreamBuilder<List<Goal>>(
        stream: _firestore.goalsStream(user.uid),
        builder: (context, goalSnap) {
          if (!goalSnap.hasData)
            return const Center(child: CircularProgressIndicator());
          final goals = goalSnap.data!;
          return StreamBuilder<List<Habit>>(
            stream: _firestore.habitsStream(user.uid),
            builder: (context, habitSnap) {
              if (!habitSnap.hasData)
                return const Center(child: CircularProgressIndicator());
              final habits = habitSnap.data!;
              if (habits.isEmpty) {
                return const Center(child: Text('No habits yet.'));
              }
              return ListView.builder(
                itemCount: habits.length,
                itemBuilder: (context, i) {
                  final habit = habits[i];
                  final goal = goals.firstWhere(
                    (g) => g.id == habit.goalId,
                    orElse: () => Goal(id: '', userId: '', title: 'Unknown'),
                  );
                  return ListTile(
                    title: Text(habit.name),
                    subtitle: Text('Goal: ${goal.title}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showEditHabitDialog(habit, goals),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _firestore.deleteHabit(habit.id);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: StreamBuilder<List<Goal>>(
        stream: _firestore.goalsStream(user.uid),
        builder: (context, snapshot) {
          final goals = snapshot.data ?? [];
          return FloatingActionButton(
            onPressed: goals.isEmpty ? null : () => _showAddHabitDialog(goals),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
