import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/habit.dart';
import 'widgets/habit_completion_tile.dart';
import 'widgets/user_points_widget.dart';

class HabitsScreen extends StatefulWidget {
  const HabitsScreen({super.key});

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _whenWhereController = TextEditingController();
  int _difficulty = 1;

  void _addHabit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final habit = Habit(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      desc: _descController.text.trim(),
      difficulty: _difficulty,
      whenWhere: _whenWhereController.text.trim(),
    );
    await _firestore.addHabit(habit);
    _descController.clear();
    _whenWhereController.clear();
    setState(() => _difficulty = 1);
    Navigator.of(context).pop();
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _whenWhereController,
                  decoration: const InputDecoration(labelText: 'When/Where'),
                ),
                DropdownButtonFormField<int>(
                  value: _difficulty,
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Difficulty ${i + 1}'),
                    ),
                  ),
                  onChanged: (v) => setState(() => _difficulty = v ?? 1),
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(onPressed: _addHabit, child: const Text('Add')),
            ],
          ),
    );
  }

  void _showEditHabitDialog(Habit habit) {
    _descController.text = habit.desc;
    _whenWhereController.text = habit.whenWhere;
    _difficulty = habit.difficulty;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                TextField(
                  controller: _whenWhereController,
                  decoration: const InputDecoration(labelText: 'When/Where'),
                ),
                DropdownButtonFormField<int>(
                  value: _difficulty,
                  items: List.generate(
                    5,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('Difficulty ${i + 1}'),
                    ),
                  ),
                  onChanged: (v) => setState(() => _difficulty = v ?? 1),
                  decoration: const InputDecoration(labelText: 'Difficulty'),
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
                    desc: _descController.text.trim(),
                    difficulty: _difficulty,
                    whenWhere: _whenWhereController.text.trim(),
                  );
                  await _firestore.updateHabit(updatedHabit);
                  _descController.clear();
                  _whenWhereController.clear();
                  setState(() => _difficulty = 1);
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
      appBar: AppBar(
        title: const Text('Habits'),
        actions: const [UserPointsWidget()],
      ),
      body: StreamBuilder<List<Habit>>(
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
              return Row(
                children: [
                  Expanded(
                    child: HabitCompletionTile(
                      habit: habit,
                      firestore: _firestore,
                      userId: user.uid,
                      onEdit: () => _showEditHabitDialog(habit),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
