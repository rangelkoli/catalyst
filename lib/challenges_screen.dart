import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/challenge.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  void _addChallenge() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _startDate == null || _endDate == null) return;
    final challenge = Challenge(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      startDate: _startDate!,
      endDate: _endDate!,
      target: int.tryParse(_targetController.text.trim()) ?? 0,
    );
    await _firestore.addChallenge(challenge);
    _titleController.clear();
    _descController.clear();
    _targetController.clear();
    _startDate = null;
    _endDate = null;
    Navigator.of(context).pop();
  }

  void _showAddChallengeDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Challenge'),
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
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(labelText: 'Target'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(() => _startDate = picked);
                        },
                        child: Text(
                          _startDate == null
                              ? 'Start Date'
                              : _startDate!.toLocal().toString().split(' ')[0],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                        child: Text(
                          _endDate == null
                              ? 'End Date'
                              : _endDate!.toLocal().toString().split(' ')[0],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _addChallenge,
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditChallengeDialog(Challenge challenge) {
    _titleController.text = challenge.title;
    _descController.text = challenge.description;
    _targetController.text = challenge.target.toString();
    _startDate = challenge.startDate;
    _endDate = challenge.endDate;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Challenge'),
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
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(labelText: 'Target'),
                  keyboardType: TextInputType.number,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null)
                            setState(() => _startDate = picked);
                        },
                        child: Text(
                          _startDate == null
                              ? 'Start Date'
                              : _startDate!.toLocal().toString().split(' ')[0],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _endDate = picked);
                        },
                        child: Text(
                          _endDate == null
                              ? 'End Date'
                              : _endDate!.toLocal().toString().split(' ')[0],
                        ),
                      ),
                    ),
                  ],
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
                  final updatedChallenge = Challenge(
                    id: challenge.id,
                    userId: challenge.userId,
                    title: _titleController.text.trim(),
                    description: _descController.text.trim(),
                    startDate: _startDate!,
                    endDate: _endDate!,
                    target: int.tryParse(_targetController.text.trim()) ?? 0,
                    progress: challenge.progress,
                  );
                  await _firestore.updateChallenge(updatedChallenge);
                  _titleController.clear();
                  _descController.clear();
                  _targetController.clear();
                  _startDate = null;
                  _endDate = null;
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
      appBar: AppBar(title: const Text('Challenges')),
      body: StreamBuilder<List<Challenge>>(
        stream: _firestore.challengesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final challenges = snapshot.data ?? [];
          if (challenges.isEmpty) {
            return const Center(child: Text('No challenges yet.'));
          }
          return ListView.builder(
            itemCount: challenges.length,
            itemBuilder: (context, i) {
              final challenge = challenges[i];
              return ListTile(
                title: Text(challenge.title),
                subtitle: Text(challenge.description),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showEditChallengeDialog(challenge),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        await _firestore.deleteChallenge(challenge.id);
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
        onPressed: _showAddChallengeDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
