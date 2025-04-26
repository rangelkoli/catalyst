import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/achievement.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  void _addAchievement() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final achievement = Achievement(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      achievedAt: DateTime.now(),
    );
    await _firestore.addAchievement(achievement);
    _titleController.clear();
    _descController.clear();
    Navigator.of(context).pop();
  }

  void _showAddAchievementDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Achievement'),
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
                onPressed: _addAchievement,
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditAchievementDialog(Achievement achievement) {
    _titleController.text = achievement.title;
    _descController.text = achievement.description;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Achievement'),
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
                  final updatedAchievement = Achievement(
                    id: achievement.id,
                    userId: achievement.userId,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    achievedAt: achievement.achievedAt,
                  );
                  await _firestore.updateAchievement(updatedAchievement);
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
      appBar: AppBar(title: const Text('Achievements')),
      body: StreamBuilder<List<Achievement>>(
        stream: _firestore.achievementsStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final achievements = snapshot.data ?? [];
          if (achievements.isEmpty) {
            return const Center(child: Text('No achievements yet.'));
          }
          return ListView.builder(
            itemCount: achievements.length,
            itemBuilder: (context, i) {
              final achievement = achievements[i];
              return ListTile(
                title: Text(achievement.title),
                subtitle: Text(achievement.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditAchievementDialog(achievement),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _firestore.deleteAchievement(achievement.id);
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
        onPressed: _showAddAchievementDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
