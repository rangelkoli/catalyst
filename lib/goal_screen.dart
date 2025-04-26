import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/goal.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void _addGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
    );
    await _firestore.addGoal(goal);
    _titleController.clear();
    _descController.clear();
    Navigator.of(context).pop();
  }

  void _showAddGoalDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(onPressed: _addGoal, child: const Text('Add')),
            ],
          ),
    );
  }

  void _showEditGoalDialog(Goal goal) {
    _titleController.text = goal.title;
    _descController.text = goal.description;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(labelText: 'Description'),
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
                  final updatedGoal = Goal(
                    id: goal.id,
                    userId: goal.userId,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    habitIds: goal.habitIds,
                    progress: goal.progress,
                  );
                  await _firestore.updateGoal(updatedGoal);
                  _titleController.clear();
                  _descController.clear();
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
      appBar: AppBar(title: const Text('Goals')),
      body: StreamBuilder<List<Goal>>(
        stream: _firestore.goalsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final goals = snapshot.data ?? [];
          if (goals.isEmpty) {
            return const Center(child: Text('No goals yet.'));
          }
          return ListView.builder(
            itemCount: goals.length,
            itemBuilder: (context, i) {
              final goal = goals[i];
              return ListTile(
                title: Text(goal.title),
                subtitle: Text(goal.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditGoalDialog(goal),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _firestore.deleteGoal(goal.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
