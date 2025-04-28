import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'services/gemini_service.dart';
import 'services/notification_helper.dart';

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

  // Choice options
  final List<String> areaOptions = [
    'Health',
    'Productivity',
    'Learning',
    'Mindfulness',
    'Finances',
    'Other...',
  ];

  final Map<String, List<String>> areaGoalOptions = {
    'Health': [
      'Feel more energetic',
      'Improve sleep quality',
      'Exercise regularly',
      'Eat healthier',
      'Other...',
    ],
    'Productivity': [
      'Finish my online course',
      'Be more organized',
      'Reduce procrastination',
      'Complete daily tasks',
      'Other...',
    ],
    'Learning': [
      'Read more books',
      'Learn a new skill',
      'Practice daily',
      'Finish a project',
      'Other...',
    ],
    'Mindfulness': [
      'Feel calmer daily',
      'Reduce stress',
      'Be more present',
      'Practice gratitude',
      'Other...',
    ],
    'Finances': [
      'Save more money',
      'Track expenses',
      'Reduce spending',
      'Increase savings',
      'Other...',
    ],
    'Other...': ['Other...'],
  };

  final Map<String, List<String>> areaHabitOptions = {
    'Health': [
      '5-minute walk',
      'Drink one glass of water',
      'Stretch for 2 minutes',
      'Eat a fruit',
      'Other...',
    ],
    'Productivity': [
      'Plan tomorrow\'s top task',
      'Focus for 15 minutes',
      'Clear workspace',
      'Check off 1 task',
      'Other...',
    ],
    'Learning': [
      'Read one article',
      'Practice for 10 minutes',
      'Watch a tutorial',
      'Review notes',
      'Other...',
    ],
    'Mindfulness': [
      '1-minute breathing',
      'Gratitude note',
      'Short meditation',
      'Mindful check-in',
      'Other...',
    ],
    'Finances': [
      'Log expenses',
      'Skip a small purchase',
      'Review budget',
      'Transfer to savings',
      'Other...',
    ],
    'Other...': ['Other...'],
  };

  final Map<String, List<String>> areaWhenWhereOptions = {
    'Health': [
      'When my first alarm rings',
      'After lunch',
      'Before bed',
      'Other...',
    ],
    'Productivity': [
      'Start of workday',
      'After lunch',
      'Before ending work',
      'Other...',
    ],
    'Learning': ['After breakfast', 'Before bed', 'During commute', 'Other...'],
    'Mindfulness': ['After waking up', 'Before bed', 'After lunch', 'Other...'],
    'Finances': ['End of day', 'After a purchase', 'Weekly review', 'Other...'],
    'Other...': ['Other...'],
  };

  final Map<String, List<String>> areaRewardOptions = {
    'Health': [
      'Watch one TV episode',
      'Enjoy a healthy treat',
      'Take a relaxing bath',
      'Other...',
    ],
    'Productivity': [
      '15 mins social media',
      'Enjoy a coffee break',
      'Watch a YouTube video',
      'Other...',
    ],
    'Learning': [
      'Listen to a podcast',
      'Read fiction',
      'Watch a favorite show',
      'Other...',
    ],
    'Mindfulness': [
      'Listen to music',
      'Take a nature walk',
      'Enjoy a treat',
      'Other...',
    ],
    'Finances': [
      'Buy a small treat',
      'Enjoy a coffee',
      'Watch a movie',
      'Other...',
    ],
    'Other...': ['Other...'],
  };

  // Fallback options for each step if area is not found
  final List<String> goalOptions = [
    'Make progress',
    'Feel accomplished',
    'Build a new habit',
    'Other...',
  ];
  final List<String> habitOptions = [
    'Do a small task',
    'Reflect for 1 minute',
    'Track my progress',
    'Other...',
  ];
  final List<String> whenWhereOptions = [
    'After waking up',
    'Before bed',
    'After lunch',
    'Other...',
  ];
  final List<String> rewardOptions = [
    'Take a short break',
    'Enjoy a treat',
    'Listen to music',
    'Other...',
  ];

  String? selectedArea;
  String customArea = '';
  String? selectedGoal;
  String customGoal = '';
  String? selectedHabit;
  String customHabit = '';
  String? selectedWhenWhere;
  String customWhenWhere = '';
  String? selectedReward;
  String customReward = '';

  final areaController = TextEditingController();
  final goalController = TextEditingController();
  final habitController = TextEditingController();
  final whenWhereController = TextEditingController();
  final rewardController = TextEditingController();

  @override
  void dispose() {
    areaController.dispose();
    goalController.dispose();
    habitController.dispose();
    whenWhereController.dispose();
    rewardController.dispose();
    super.dispose();
  }

  void nextStep() => setState(() => step++);
  void prevStep() => setState(() => step--);

  Future<void> saveToFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    final docSnap = await userDoc.get();
    if (!docSnap.exists) {
      // Create the user doc with minimal info and onboarded: false
      await userDoc.set({
        'email': FirebaseAuth.instance.currentUser?.email ?? '',
        'onboarded': false,
      });
    }
    await userDoc.set({'onboarded': true}, SetOptions(merge: true));

    // Save goal
    final goalId = FirebaseFirestore.instance.collection('goals').doc().id;
    await FirebaseFirestore.instance.collection('goals').doc(goalId).set({
      'id': goalId,
      'userId': uid,
      'title': area,
      'description': goalDesc,
      'habitIds': [],
      'progress': 0,
    });

    // Save habits
    for (final habit in habits) {
      final habitId = FirebaseFirestore.instance.collection('habits').doc().id;
      await FirebaseFirestore.instance.collection('habits').doc(habitId).set({
        'id': habitId,
        'userId': uid,
        'desc': habit['desc'],
        'difficulty': habit['difficulty'],
        'whenWhere': habit['whenWhere'],
      });
    }

    // Save rewards
    for (final reward in rewards) {
      final rewardId =
          FirebaseFirestore.instance.collection('rewards').doc().id;
      await FirebaseFirestore.instance.collection('rewards').doc(rewardId).set({
        'id': rewardId,
        'userId': uid,
        'desc': reward['desc'],
      });
    }
  }

  Widget buildStep() {
    switch (step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to LiFE Ledger!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            const Text(
              "Let's set up your personal economy for building better habits. This quick wizard helps you define what matters most to you right now.",
            ),
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
        final areaList = areaOptions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's one area of your life you'd like to focus on improving right now? (e.g., Health, Productivity, Learning, Mindfulness, Finances)",
            ),
            const SizedBox(height: 16),
            ...(areaList ?? []).map(
              (option) => SelectableOptionTile(
                label: option,
                selected: selectedArea == option,
                onTap: () {
                  setState(() {
                    selectedArea = option;
                    if (option != 'Other...') customArea = '';
                    // Reset dependent selections
                    selectedGoal = null;
                    customGoal = '';
                    selectedHabit = null;
                    customHabit = '';
                    selectedWhenWhere = null;
                    customWhenWhere = '';
                    selectedReward = null;
                    customReward = '';
                  });
                },
              ),
            ),
            if (selectedArea == 'Other...')
              TextField(
                decoration: const InputDecoration(labelText: 'Custom Area'),
                onChanged: (val) => customArea = val,
              ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (step > 0)
                  TextButton(onPressed: prevStep, child: const Text('Back')),
                ElevatedButton(
                  onPressed:
                      selectedArea != null &&
                              (selectedArea != 'Other...' ||
                                  customArea.isNotEmpty)
                          ? () {
                            setState(() {
                              area =
                                  selectedArea == 'Other...'
                                      ? customArea
                                      : selectedArea!;
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
        final goalList =
            selectedArea != null && areaGoalOptions.containsKey(selectedArea!)
                ? areaGoalOptions[selectedArea!]
                : goalOptions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Can you briefly describe what 'success' in $area looks like for you in the next month or two? (Optional)",
            ),
            const SizedBox(height: 16),
            ...(goalList ?? []).map(
              (option) => SelectableOptionTile(
                label: option,
                selected: selectedGoal == option,
                onTap: () {
                  setState(() {
                    selectedGoal = option;
                    if (option != 'Other...') customGoal = '';
                  });
                },
              ),
            ),
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
                  onPressed:
                      selectedGoal != null &&
                              (selectedGoal != 'Other...' ||
                                  customGoal.isNotEmpty)
                          ? () {
                            setState(() {
                              goalDesc =
                                  selectedGoal == 'Other...'
                                      ? customGoal
                                      : selectedGoal!;
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
        final habitList =
            selectedArea != null && areaHabitOptions.containsKey(selectedArea!)
                ? areaHabitOptions[selectedArea!]
                : habitOptions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Thinking about your goal of " +
                  (goalDesc.isNotEmpty ? goalDesc : area) +
                  ", what's a small, simple action you could take almost every day to move towards it?",
            ),
            const SizedBox(height: 16),
            ...(habitList ?? []).map(
              (option) => SelectableOptionTile(
                label: option,
                selected: selectedHabit == option,
                onTap: () {
                  setState(() {
                    selectedHabit = option;
                    if (option != 'Other...') customHabit = '';
                  });
                },
              ),
            ),
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
                  onPressed:
                      selectedHabit != null &&
                              (selectedHabit != 'Other...' ||
                                  customHabit.isNotEmpty)
                          ? () {
                            setState(() {
                              habitDesc =
                                  selectedHabit == 'Other...'
                                      ? customHabit
                                      : selectedHabit!;
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
            Text(
              "On a scale of 1 (Very Easy) to 5 (Quite Challenging), how difficult does '$habitDesc' feel for you right now?",
            ),
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
                ElevatedButton(onPressed: nextStep, child: const Text('Next')),
              ],
            ),
          ],
        );
      case 5:
        final whenWhereList =
            selectedArea != null &&
                    areaWhenWhereOptions.containsKey(selectedArea!)
                ? areaWhenWhereOptions[selectedArea!]
                : whenWhereOptions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "To make '$habitDesc' easier to stick to, when and where will you typically do it? (Optional)",
            ),
            const SizedBox(height: 16),
            ...(whenWhereList ?? []).map(
              (option) => SelectableOptionTile(
                label: option,
                selected: selectedWhenWhere == option,
                onTap: () {
                  setState(() {
                    selectedWhenWhere = option;
                    if (option != 'Other...') customWhenWhere = '';
                  });
                },
              ),
            ),
            if (selectedWhenWhere == 'Other...')
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Custom When/Where',
                ),
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
                      habitWhenWhere =
                          selectedWhenWhere == 'Other...'
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
            const Text(
              "Great! Let's add another small habit (we recommend starting with 3-5 total).",
            ),
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
              ...habits.map(
                (h) => ListTile(
                  leading: const Icon(Icons.check),
                  title: Text(h['desc'] ?? ''),
                  subtitle: Text('Difficulty: ${h['difficulty']}'),
                ),
              ),
          ],
        );
      case 7:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Now, let's define some rewards you can 'buy' with the points you earn. These should be things you genuinely enjoy!",
            ),
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
        final rewardList =
            selectedArea != null && areaRewardOptions.containsKey(selectedArea!)
                ? areaRewardOptions[selectedArea!]
                : rewardOptions;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What's a simple reward you'd like to treat yourself to? (e.g., Watch one TV episode, Enjoy a coffee break, 15 mins social media, Listen to a podcast)",
            ),
            const SizedBox(height: 16),
            ...(rewardList ?? []).map(
              (option) => SelectableOptionTile(
                label: option,
                selected: selectedReward == option,
                onTap: () {
                  setState(() {
                    selectedReward = option;
                    if (option != 'Other...') customReward = '';
                  });
                },
              ),
            ),
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
                  onPressed:
                      selectedReward != null &&
                              (selectedReward != 'Other...' ||
                                  customReward.isNotEmpty)
                          ? () {
                            setState(() {
                              rewardDesc =
                                  selectedReward == 'Other...'
                                      ? customReward
                                      : selectedReward!;
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
            const Text("Want to add another reward?"),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Add current reward if not already added
                    if (rewardDesc.isNotEmpty &&
                        (rewards.isEmpty ||
                            rewards.last['desc'] != rewardDesc)) {
                      rewards.add({'desc': rewardDesc});
                    }
                    setState(() => step = 8);
                  },
                  child: const Text('Add Another Reward'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // Add current reward if not already added
                    if (rewardDesc.isNotEmpty &&
                        (rewards.isEmpty ||
                            rewards.last['desc'] != rewardDesc)) {
                      rewards.add({'desc': rewardDesc});
                    }
                    setState(() => step = 11);
                  },
                  child: const Text('Done for Now'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (rewards.isNotEmpty)
              ...rewards.map(
                (r) => ListTile(
                  leading: const Icon(Icons.card_giftcard),
                  title: Text(r['desc'] ?? ''),
                ),
              ),
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
            ...habits.map(
              (h) => ListTile(
                leading: const Icon(Icons.check),
                title: Text(h['desc'] ?? ''),
                subtitle: Text('Difficulty: ${h['difficulty']}'),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Rewards:'),
            ...rewards.map(
              (r) => ListTile(
                leading: const Icon(Icons.card_giftcard),
                title: Text(r['desc'] ?? ''),
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () async {
                  await saveToFirestore();
                  await NotificationHelper.initialize();
                  // Prepare data for Gemini
                  final geminiPrompt = '''

**Role:** You are an expert setup assistant for the LiFE Ledger app, specializing in translating user goals into effective, personalized starting configurations based on behavioral science principles (micro-habits, goal-setting, reinforcement schedules, self-regulation).

**Context:** The user has completed the "Know Thyself" onboarding wizard. Your task is to process their answers to create an initial set of habits and rewards that are motivating, achievable, and balanced. Aim to maximize the user's chances of early success and sustained engagement.

**Core Principles to Apply:**
* **Goal Decomposition:** Break down the `Success Description` into concrete actions.
* **Micro-Habits:** Define habits that are specific, small, and require low activation energy.
* **Starting Small & Early Wins:** Ensure at least one habit is rated as very easy (approx. 5 points).
* **User-Defined Motivation:** Base rewards primarily on user ideas.
* **Balanced Reinforcement:** Include both easily attainable (low-cost) and aspirational (higher-cost) rewards.
* **Cue-Response Links:** Suggest potential triggers/times for habits (Implementation Intentions/Habit Stacking).
* **Transparency:** Optionally explain the reasoning behind suggestions.

**Input Data from User Onboarding:**

* **Focus Area:** $area *(e.g., "Health", "Productivity", "Learning", "Mindfulness")*
* **Success Description:** $goalDesc *(e.g., "Feel more energetic", "Finish my online course", "Be more present daily")*
* **User-Selected Habits:** ${habits.map((h) => h['desc']).toList()} *(e.g., ["Go for a walk", "Meditate", "Focus work"])*
* **User-Selected Rewards:** ${rewards.map((r) => r['desc']).toList()} *(e.g., ["Watch one TV episode", "Coffee break"])*
* **Initial Habit Idea:** ${habits.isNotEmpty ? habits.first['desc'] : ''} *(e.g., "Go for a walk", "Meditate", "Focus work")*
* **Perceived Difficulty (1-5):** ${habits.isNotEmpty ? habits.first['difficulty'] : habitDifficulty} *(e.g., 3)*
* **Implementation Intention (Optional):** ${habits.isNotEmpty ? habits.first['whenWhere'] : ''} *(e.g., "After my morning coffee", "When I get home from work")*
* **Reward Idea(s):** ${rewards.map((r) => r['desc']).toList()} *(e.g., "Watch one TV episode", "Coffee break", "Read fiction", "Listen to music")*
* **Desired Reward Frequency/Effort Balance (Implied):** User set initial reward cost suggesting they want it accessible every 1-2 days

**Task:**

1.  **Analyze Goal & Initial Habit:** Deeply analyze the `Focus Area` and `Success Description` to understand the user's underlying objective. Refine the `Initial Habit Idea` into a specific micro-habit if necessary.
2.  **Generate Supporting Habits:**
    * Generate 2-4 *additional* specific, small, daily/near-daily micro-habits that directly support the `Success Description` and `Focus Area`. Aim for a total of 3-5 habits.
    * **Ensure at least one generated habit is very easy (target 5 points).**
    * *Tailoring Examples:*
        * *Health:* Hydration, short walks, stairs, stretching, healthy snack choice.
        * *Productivity:* Plan day, focus block (Pomodoro), clear workspace, single-tasking for 15 mins.
        * *Learning:* Read 1 page/article, 5 mins language app, watch short tutorial, practice 1 concept.
        * *Mindfulness:* 1-minute breathing, mindful moment check-in, short body scan, gratitude note.
3.  **Assign Habit Points & Rationale:**
    * Assign point values (integer) based on perceived difficulty (Scale: 1=5, 2=8, 3=10, 4=13, 5=15 pts). Use the `Perceived Difficulty` rating for the initial habit and estimate for others relative to the goal.
    * For each habit, include an optional `rationale` (string, max 1 sentence) explaining how it contributes to the user's goal (e.g., "Builds consistency", "Provides energy boost").
    * Include an optional `suggested_cue` (string) suggesting a potential time or trigger (e.g., "Before breakfast", "During commute", "After existing habit X").
4.  **Generate Rewards & Costs:**
    * Refine user's `Reward Idea(s)` into specific rewards. Generate 1-2 additional ideas if needed, aiming for 2-3 total.
    * Assign point costs (integer). **Ensure at least one reward is low-cost** (e.g., earnable with 1-2 successful moderate habits) and **at least one is higher-cost** (requiring several successful habits). Base costs on potential daily earnings and `user_reward_cost_setting_context`.
    * Include an optional `rationale` (string, max 1 sentence) for reward costs (e.g., "Accessible daily motivator", "Meaningful goal to work towards").
5.  **Format Output:** Present the results as a single, valid JSON object. Include an `adaptive_setup` flag set to `true`.

**Constraints:**

* Output MUST be a valid JSON object.
* No explanatory text outside the JSON structure.
* Habits must be small, actionable micro-habits.
* Point values and costs must be integers.
* Optional fields (`rationale`, `suggested_cue`) should only be included if meaningful content can be generated for them.

**Output Format (JSON):**

```json
{
  "adaptive_setup": true,
  "habits": [
    {
      "name": "string",
      "points": integer,
      "rationale": "string (optional)",
      "suggested_cue": "string (optional)",
      "suggested_notification_time": "string (24h, e.g. '07:30', optional)"
    }
    // ... up to 5 habits total
  ],
  "rewards": [
    {
      "name": "string",
      "cost": integer,
      "rationale": "string (optional)"
    }
    // ... 2-3 rewards total
  ]
}
```
''';
                  final gemini = GeminiService(
                    dotenv.env['GEMINI_API_KEY'] ?? '',
                  );
                  final geminiResult = await gemini.generateText(geminiPrompt);
                  debugPrint('Gemini result: $geminiResult');
                  // Parse and save Gemini habits and rewards to Firebase
                  try {
                    if (geminiResult != null) {
                      // Remove Markdown code block markers if present
                      String cleaned = geminiResult.trim();
                      if (cleaned.startsWith('```')) {
                        final firstNewline = cleaned.indexOf('\n');
                        if (firstNewline != -1) {
                          cleaned = cleaned.substring(firstNewline + 1);
                        }
                        if (cleaned.endsWith('```')) {
                          cleaned = cleaned.substring(0, cleaned.length - 3);
                        }
                        cleaned = cleaned.trim();
                      }
                      final geminiJson = jsonDecode(cleaned);
                      final uid = FirebaseAuth.instance.currentUser?.uid;
                      if (uid != null) {
                        // Save habits
                        if (geminiJson['habits'] is List) {
                          int notifId = 1000;
                          for (final habit in geminiJson['habits']) {
                            final habitId =
                                FirebaseFirestore.instance
                                    .collection('habits')
                                    .doc()
                                    .id;
                            await FirebaseFirestore.instance
                                .collection('habits')
                                .doc(habitId)
                                .set({
                                  'id': habitId,
                                  'userId': uid,
                                  'desc': habit['name'],
                                  'difficulty': habit['points'],
                                  if (habit['rationale'] != null)
                                    'rationale': habit['rationale'],
                                  if (habit['suggested_cue'] != null)
                                    'whenWhere': habit['suggested_cue'],
                                });
                            // Schedule notification if suggested_notification_time exists
                            if (habit['suggested_notification_time'] != null &&
                                habit['suggested_notification_time']
                                    .toString()
                                    .contains(':')) {
                              await NotificationHelper.scheduleHabitNotification(
                                id: notifId++,
                                title: 'Habit Reminder',
                                body: habit['name'],
                                time24h: habit['suggested_notification_time'],
                              );
                            }
                          }
                        }
                        // Save rewards
                        if (geminiJson['rewards'] is List) {
                          for (final reward in geminiJson['rewards']) {
                            final rewardId =
                                FirebaseFirestore.instance
                                    .collection('rewards')
                                    .doc()
                                    .id;
                            await FirebaseFirestore.instance
                                .collection('rewards')
                                .doc(rewardId)
                                .set({
                                  'id': rewardId,
                                  'userId': uid,
                                  'desc': reward['name'],
                                  'cost': reward['cost'],
                                  if (reward['rationale'] != null)
                                    'rationale': reward['rationale'],
                                });
                          }
                        }
                      }
                    }
                  } catch (e) {
                    debugPrint('Error parsing/saving Gemini result: $e');
                  }
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
      body: Padding(padding: const EdgeInsets.all(24.0), child: buildStep()),
    );
  }
}

class SelectableOptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SelectableOptionTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? Colors.green[100] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow:
            selected
                ? [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
                : [],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? Colors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? Colors.green : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child:
                    selected
                        ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                          key: ValueKey('check'),
                        )
                        : const SizedBox.shrink(key: ValueKey('empty')),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
}
