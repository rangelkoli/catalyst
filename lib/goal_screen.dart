import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/goal.dart';
import 'models/habit.dart';
import 'package:confetti/confetti.dart';
import 'dart:math';
import 'package:rxdart/rxdart.dart';
import 'widgets/user_points_widget.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final ConfettiController _confettiController = ConfettiController(
    duration: const Duration(seconds: 2),
  );
  final List<String> _motivationalQuotes = [
    'Keep pushing forward!',
    'Small steps every day!',
    'You are closer than you think!',
    'Stay consistent and win!',
    'Progress, not perfection!',
  ];
  DateTime? _selectedTargetDate;
  int _expandedIndex = -1;
  List<String> _selectedHabitIds = [];

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _addGoal() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final goal = Goal(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      habitIds: List<String>.from(_selectedHabitIds),
      targetDate: _selectedTargetDate,
    );
    await _firestore.addGoal(goal);
    _titleController.clear();
    _descController.clear();
    _selectedTargetDate = null;
    _selectedHabitIds = [];
    Navigator.of(context).pop();
  }

  void _showAddGoalDialog() {
    _selectedTargetDate = null;
    _selectedHabitIds = [];
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Goal'),
            content: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedTargetDate == null
                              ? 'No target date'
                              : 'Target: ${_selectedTargetDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedTargetDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Habit>>(
                    stream: _firestore.habitsStream(user!.uid),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      final habits = snap.data!;
                      if (habits.isEmpty)
                        return const Text('No habits to link.');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Link Habits:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...habits.map(
                            (habit) => CheckboxListTile(
                              value: _selectedHabitIds.contains(habit.id),
                              title: Text(habit.desc),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedHabitIds.add(habit.id);
                                  } else {
                                    _selectedHabitIds.remove(habit.id);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
    _selectedTargetDate = goal.targetDate;
    _selectedHabitIds = List<String>.from(goal.habitIds);
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Goal'),
            content: SingleChildScrollView(
              child: Column(
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _selectedTargetDate == null
                              ? 'No target date'
                              : 'Target: ${_selectedTargetDate!.toLocal().toString().split(' ')[0]}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedTargetDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              _selectedTargetDate = picked;
                            });
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<List<Habit>>(
                    stream: _firestore.habitsStream(user!.uid),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      final habits = snap.data!;
                      if (habits.isEmpty)
                        return const Text('No habits to link.');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Link Habits:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...habits.map(
                            (habit) => CheckboxListTile(
                              value: _selectedHabitIds.contains(habit.id),
                              title: Text(habit.desc),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked == true) {
                                    _selectedHabitIds.add(habit.id);
                                  } else {
                                    _selectedHabitIds.remove(habit.id);
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
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
                    habitIds: List<String>.from(_selectedHabitIds),
                    progress: goal.progress,
                    tags: goal.tags,
                    streak: goal.streak,
                    targetDate: _selectedTargetDate,
                  );
                  await _firestore.updateGoal(updatedGoal);
                  _titleController.clear();
                  _descController.clear();
                  _selectedTargetDate = null;
                  _selectedHabitIds = [];
                  Navigator.of(context).pop();
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _celebrate() {
    _confettiController.play();
  }

  Widget _buildGoalProgress(Goal goal, String userId) {
    if (goal.habitIds.isEmpty) {
      return const Text('No linked habits');
    }
    final today = DateTime(2025, 4, 28); // Use DateTime.now() in production
    return StreamBuilder<List<Habit>>(
      stream: _firestore.habitsStream(userId),
      builder: (context, habitSnap) {
        if (!habitSnap.hasData) return const LinearProgressIndicator();
        final linkedHabits =
            habitSnap.data!.where((h) => goal.habitIds.contains(h.id)).toList();
        if (linkedHabits.isEmpty) {
          return const Text('No linked habits');
        }
        return StreamBuilder<List<List<String>>>(
          stream: CombineLatestStream.list(
            linkedHabits.map(
              (habit) => _firestore.habitCompletionsStream(
                userId: userId,
                habitId: habit.id,
              ),
            ),
          ),
          builder: (context, compSnap) {
            if (!compSnap.hasData) return const LinearProgressIndicator();
            final completions = compSnap.data!;
            int completedToday = 0;
            for (final habitDates in completions) {
              if (habitDates.contains(
                '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}',
              )) {
                completedToday++;
              }
            }
            final percent =
                linkedHabits.isEmpty
                    ? 0.0
                    : completedToday / linkedHabits.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: percent.toDouble()),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      backgroundColor: Colors.grey.shade300,
                      color: Colors.blue,
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedToday of ${linkedHabits.length} habits completed today',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        actions: const [UserPointsWidget()],
      ),
      body: Stack(
        children: [
          StreamBuilder<List<Goal>>(
            stream: _firestore.goalsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final goals = snapshot.data ?? [];
              if (goals.isEmpty) {
                return const Center(child: Text('No goals yet.'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                separatorBuilder: (context, i) => const SizedBox(height: 16),
                itemBuilder: (context, i) {
                  final goal = goals[i];
                  final isExpanded = _expandedIndex == i;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          setState(() {
                            _expandedIndex = isExpanded ? -1 : i;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade100,
                                    child: Icon(
                                      Icons.flag,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          goal.title,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 6,
                                          children:
                                              goal.tags
                                                  .map(
                                                    (tag) => Chip(
                                                      label: Text(tag),
                                                      backgroundColor:
                                                          Colors.blue.shade50,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                        const SizedBox(height: 12),
                                        _buildGoalProgress(goal, user.uid),
                                        if (goal.targetDate != null) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 16,
                                                color: Colors.teal,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                'Target: ${goal.targetDate!.toLocal().toString().split(' ')[0]}',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  color: Colors.teal,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.orange,
                                        ),
                                        onPressed:
                                            () => _showEditGoalDialog(goal),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                        ),
                                        onPressed: () async {
                                          await _firestore.deleteGoal(goal.id);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (isExpanded) ...[
                                const SizedBox(height: 12),
                                Text(
                                  goal.description,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_fire_department,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 6),
                                    Text('Streak: ${goal.streak} days'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _motivationalQuotes[goal.id.hashCode %
                                      _motivationalQuotes.length],
                                  style: const TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.green,
                                  ),
                                ),
                                if (goal.progress == 100)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.celebration),
                                      label: const Text('Celebrate!'),
                                      onPressed: _celebrate,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              maxBlastForce: 20,
              minBlastForce: 8,
              gravity: 0.3,
              shouldLoop: false,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
