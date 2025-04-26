import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class KnowThyselfWizard extends StatefulWidget {
  final VoidCallback onComplete;
  const KnowThyselfWizard({super.key, required this.onComplete});

  @override
  State<KnowThyselfWizard> createState() => _KnowThyselfWizardState();
}

class _KnowThyselfWizardState extends State<KnowThyselfWizard> {
  int step = 0;
  String area = '';
  String goalDesc = '';
  List<Map<String, dynamic>> habits = [];
  String habitDesc = '';
  int habitDifficulty = 1;
  String habitWhenWhere = '';
  List<Map<String, dynamic>> rewards = [];
  String rewardDesc = '';
  int rewardCost = 2;

  // Choice options
  final List<String> areaOptions = [
    'Health', 'Productivity', 'Learning', 'Mindfulness', 'Finances', 'Other...'
  ];
  String? selectedArea;
  String customArea = '';

  final List<String> goalOptions = [
    'Feel more energetic',
    'Finish my online course',
    'Feel calmer daily',
    'Save more money',
    'Other...'
  ];
  String? selectedGoal;
  String customGoal = '';

  final List<String> habitOptions = [
    '5-minute walk',
    'Drink one glass of water',
    'Stretch for 2 minutes',
    'Plan tomorrow\'s top task',
    'Read one article',
    'Other...'
  ];
  String? selectedHabit;
  String customHabit = '';

  final List<String> whenWhereOptions = [
    'When my first alarm rings',
    'After lunch',
    'Before bed',
    'Other...'
  ];
  String? selectedWhenWhere;
  String customWhenWhere = '';

  final List<String> rewardOptions = [
    'Watch one TV episode',
    'Enjoy a coffee break',
    '15 mins social media',
    'Listen to a podcast',
    'Other...'
  ];
  String? selectedReward;
  String customReward = '';

  final areaController = TextEditingController();
  final goalController = TextEditingController();
  final habitController = TextEditingController();
  final whenWhereController = TextEditingController();
  final rewardController = TextEditingController();
  final rewardCostController = TextEditingController(text: '2');

  @override
  void dispose() {
    areaController.dispose();
    goalController.dispose();
    habitController.dispose();
    whenWhereController.dispose();
    rewardController.dispose();
    rewardCostController.dispose();
    super.dispose();
  }

  void nextStep() => setState(() => step++);
  void prevStep() => setState(() => step--);

  Future<void> saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    await userDoc.set({
      'area': area,
      'goalDesc': goalDesc,
      'habits': habits,
      'rewards': rewards,
      'onboarded': true,
    }, SetOptions(merge: true));
  }

  Widget buildStep() {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome to LiFE Ledger!', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            const Text("Let's set up your personal economy for building better habits. This quick wizard helps you define what matters most to you right now."),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: nextStep,
                child: const Text('Get Started'),
              ),
            ),
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What's one area of your life you'd like to focus on improving right now? (e.g., Health, Productivity, Learning, Mindfulness, Finances)"),
            const SizedBox(height: 16),
            ...areaOptions.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedArea,
                  onChanged: (val) {
                    setState(() {
                      selectedArea = val;
                      if (val != 'Other...') customArea = '';
                    });
                  },
                )),
            if (selectedArea == 'Other...')
              TextField(
                decoration: const InputDecoration(labelText: 'Custom Area'),
                onChanged: (val) => customArea = val,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (step > 0) TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: selectedArea != null && (selectedArea != 'Other...' || customArea.isNotEmpty)
                      ? () {
                          setState(() {
                            area = selectedArea == 'Other...' ? customArea : selectedArea!;
                          });
                          nextStep();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Can you briefly describe what 'success' in $area looks like for you in the next month or two? (Optional)"),
            const SizedBox(height: 16),
            ...goalOptions.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedGoal,
                  onChanged: (val) {
                    setState(() {
                      selectedGoal = val;
                      if (val != 'Other...') customGoal = '';
                    });
                  },
                )),
            if (selectedGoal == 'Other...')
              TextField(
                decoration: const InputDecoration(labelText: 'Custom Goal'),
                onChanged: (val) => customGoal = val,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: selectedGoal != null && (selectedGoal != 'Other...' || customGoal.isNotEmpty)
                      ? () {
                          setState(() {
                            goalDesc = selectedGoal == 'Other...' ? customGoal : selectedGoal!;
                          });
                          nextStep();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Thinking about your goal of ${goalDesc.isNotEmpty ? goalDesc : area}, what's a small, simple action you could take almost every day to move towards it?"),
            const SizedBox(height: 16),
            ...habitOptions.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedHabit,
                  onChanged: (val) {
                    setState(() {
                      selectedHabit = val;
                      if (val != 'Other...') customHabit = '';
                    });
                  },
                )),
            if (selectedHabit == 'Other...')
              TextField(
                decoration: const InputDecoration(labelText: 'Custom Habit'),
                onChanged: (val) => customHabit = val,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: selectedHabit != null && (selectedHabit != 'Other...' || customHabit.isNotEmpty)
                      ? () {
                          setState(() {
                            habitDesc = selectedHabit == 'Other...' ? customHabit : selectedHabit!;
                          });
                          nextStep();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 4:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("On a scale of 1 (Very Easy) to 5 (Quite Challenging), how difficult does '$habitDesc' feel for you right now?"),
            const SizedBox(height: 16),
            Slider(
              value: habitDifficulty.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              label: habitDifficulty.toString(),
              onChanged: (v) => setState(() => habitDifficulty = v.round()),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: nextStep,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 5:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("To make '$habitDesc' easier to stick to, when and where will you typically do it? (Optional)"),
            const SizedBox(height: 16),
            ...whenWhereOptions.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedWhenWhere,
                  onChanged: (val) {
                    setState(() {
                      selectedWhenWhere = val;
                      if (val != 'Other...') customWhenWhere = '';
                    });
                  },
                )),
            if (selectedWhenWhere == 'Other...')
              TextField(
                decoration: const InputDecoration(labelText: 'Custom When/Where'),
                onChanged: (val) => customWhenWhere = val,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      habitWhenWhere = selectedWhenWhere == 'Other...'
                          ? customWhenWhere
                          : (selectedWhenWhere ?? '');
                      habits.add({
                        'desc': habitDesc,
                        'difficulty': habitDifficulty,
                        'whenWhere': habitWhenWhere,
                      });
                      // Reset for next habit
                      selectedHabit = null;
                      customHabit = '';
                      selectedWhenWhere = null;
                      customWhenWhere = '';
                      habitDesc = '';
                      habitWhenWhere = '';
                      habitDifficulty = 1;
                    });
                    nextStep();
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 6:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Great! Let's add another small habit (we recommend starting with 3-5 total)."),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      habitDesc = '';
                      habitDifficulty = 1;
                      habitWhenWhere = '';
                    });
                    nextStep(); // Go to habit input again
                  },
                  child: const Text('Add Another Habit'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => step = 7),
                  child: const Text("Okay, That's Enough for Now"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (habits.isNotEmpty)
              ...habits.map((h) => ListTile(
                    leading: const Icon(Icons.check),
                    title: Text(h['desc'] ?? ''),
                    subtitle: Text('Difficulty: ${h['difficulty']}'),
                  )),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Now, let's define some rewards you can 'buy' with the points you earn. These should be things you genuinely enjoy!"),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: nextStep,
                child: const Text('Next'),
              ),
            ),
          ],
        );
      case 8:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("What's a simple reward you'd like to treat yourself to? (e.g., Watch one TV episode, Enjoy a coffee break, 15 mins social media, Listen to a podcast)"),
            const SizedBox(height: 16),
            ...rewardOptions.map((option) => RadioListTile<String>(
                  title: Text(option),
                  value: option,
                  groupValue: selectedReward,
                  onChanged: (val) {
                    setState(() {
                      selectedReward = val;
                      if (val != 'Other...') customReward = '';
                    });
                  },
                )),
            if (selectedReward == 'Other...')
              TextField(
                decoration: const InputDecoration(labelText: 'Custom Reward'),
                onChanged: (val) => customReward = val,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: selectedReward != null && (selectedReward != 'Other...' || customReward.isNotEmpty)
                      ? () {
                          setState(() {
                            rewardDesc = selectedReward == 'Other...' ? customReward : selectedReward!;
                          });
                          nextStep();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 9:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("How many 'Habit Points' should this reward cost? (e.g., 2-3 successful habit completions)"),
            const SizedBox(height: 16),
            TextField(
              controller: rewardCostController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Point Cost'),
              onChanged: (v) {
                setState(() {
                  rewardCost = int.tryParse(v) ?? 2;
                });
              },
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      rewards.add({
                        'desc': rewardDesc,
                        'cost': rewardCost,
                      });
                      rewardController.clear();
                      rewardCostController.text = '2';
                      rewardDesc = '';
                      rewardCost = 2;
                    });
                    nextStep();
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        );
      case 10:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Want to add another reward?"),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => setState(() => step = 8),
                  child: const Text('Add Another Reward'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () => setState(() => step = 11),
                  child: const Text('Done for Now'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (rewards.isNotEmpty)
              ...rewards.map((r) => ListTile(
                    leading: const Icon(Icons.card_giftcard),
                    title: Text(r['desc'] ?? ''),
                    subtitle: Text('Cost: ${r['cost']}'),
                  )),
          ],
        );
      case 11:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Setup Complete! Here's your starting LiFE Ledger:"),
            const SizedBox(height: 16),
            Text('Area: $area'),
            if (goalDesc.isNotEmpty) Text('Goal: $goalDesc'),
            const SizedBox(height: 16),
            const Text('Habits:'),
            ...habits.map((h) => ListTile(
                  leading: const Icon(Icons.check),
                  title: Text(h['desc'] ?? ''),
                  subtitle: Text('Difficulty: ${h['difficulty']}'),
                )),
            const SizedBox(height: 16),
            const Text('Rewards:'),
            ...rewards.map((r) => ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: Text(r['desc'] ?? ''),
                  subtitle: Text('Cost: ${r['cost']}'),
                )),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () async {
                  await saveToFirestore();
                  widget.onComplete();
                },
                child: const Text('Start Tracking!'),
              ),
            ),
          ],
        );
      default:
        return const Center(child: Text('Unknown step'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Know Thyself Wizard'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: buildStep(),
      ),
    );
  }
}
