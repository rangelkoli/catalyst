import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/reward.dart';
import 'widgets/user_points_widget.dart';

class RewardScreen extends StatefulWidget {
  const RewardScreen({super.key});

  @override
  State<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends State<RewardScreen> {
  final FirestoreService _firestore = FirestoreService();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _costController = TextEditingController();
  final TextEditingController _rationaleController = TextEditingController();
  Reward? _editingReward;

  void _showRewardDialog({Reward? reward}) {
    if (reward != null) {
      _descController.text = reward.desc;
      _costController.text = reward.cost.toString();
      _rationaleController.text = reward.rationale ?? '';
      _editingReward = reward;
    } else {
      _descController.clear();
      _costController.clear();
      _rationaleController.clear();
      _editingReward = null;
    }
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(reward == null ? 'Define Reward' : 'Edit Reward'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    labelText: 'Reward Description',
                  ),
                ),
                TextField(
                  controller: _costController,
                  decoration: const InputDecoration(labelText: 'Point Cost'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: _rationaleController,
                  decoration: const InputDecoration(
                    labelText: 'Why is this motivating? (optional)',
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'You are in control: define what rewards motivate you and set their point cost. This is your personal economy!',
                  style: TextStyle(fontSize: 12, color: Colors.green),
                  textAlign: TextAlign.center,
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
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  final reward = Reward(
                    id:
                        _editingReward?.id ??
                        DateTime.now().millisecondsSinceEpoch.toString(),
                    userId: user.uid,
                    desc: _descController.text.trim(),
                    cost: int.tryParse(_costController.text.trim()) ?? 0,
                    rationale:
                        _rationaleController.text.trim().isEmpty
                            ? null
                            : _rationaleController.text.trim(),
                    redeemedCount: _editingReward?.redeemedCount ?? 0,
                  );
                  if (_editingReward == null) {
                    await _firestore.addReward(reward);
                  } else {
                    await _firestore.updateReward(reward);
                  }
                  Navigator.of(context).pop();
                },
                child: Text(reward == null ? 'Add' : 'Save'),
              ),
            ],
          ),
    );
  }

  void _redeemReward(Reward reward) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    // Calculate available points (earned - spent)
    final habits = await _firestore.habitsStream(user.uid).first;
    final completionsFutures = habits.map(
      (habit) =>
          _firestore
              .habitCompletionsStream(userId: user.uid, habitId: habit.id)
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
    final rewards = await _firestore.rewardsStream(user.uid).first;
    final spent = rewards.fold<int>(
      0,
      (sum, r) =>
          sum +
          ((r.cost > 0 ? r.cost : 0) *
              (r.redeemedCount > 0 ? r.redeemedCount : 0)),
    );
    final availablePoints = totalPoints - spent;
    if (availablePoints >= reward.cost) {
      await _firestore.redeemReward(reward.id);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have enough points. Do more habits!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rewards'),
        actions: const [UserPointsWidget()],
      ),
      body: StreamBuilder<List<Reward>>(
        stream: _firestore.rewardsStream(user.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final rewards = snapshot.data!;
          if (rewards.isEmpty) {
            return const Center(
              child: Text('No rewards yet. Define your own!'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rewards.length,
            separatorBuilder: (context, i) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final reward = rewards[i];
              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.card_giftcard,
                    color: Colors.purple,
                  ),
                  title: Text(reward.desc),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cost: ${reward.cost} points'),
                      if (reward.rationale != null)
                        Text(
                          'Why: ${reward.rationale!}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      if (reward.redeemedCount > 0)
                        Text(
                          'Redeemed: ${reward.redeemedCount}x',
                          style: const TextStyle(color: Colors.green),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _showRewardDialog(reward: reward),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          await _firestore.deleteReward(reward.id);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.redeem, color: Colors.blue),
                        onPressed: () => _redeemReward(reward),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRewardDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Define a new reward',
      ),
    );
  }
}
