import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'models/goal.dart';
import 'models/habit.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
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
                return ListView.builder(
                  itemCount: habits.length,
                  itemBuilder: (context, i) {
                    final habit = habits[i];
                    return ListTile(
                      title: Text(habit.name),
                      subtitle: Text('Streak: ${habit.streak}'),
                      trailing: Text('Points: ${habit.points}'),
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
