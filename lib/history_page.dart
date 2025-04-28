import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String filter = 'All';
  final List<Map<String, dynamic>> completedHabits = [
    {'title': 'Drink Water', 'date': '2025-04-25'},
    {'title': 'Morning Run', 'date': '2025-04-26'},
  ];
  final List<Map<String, dynamic>> purchasedRewards = [
    {'title': 'Coffee Coupon', 'date': '2025-04-20'},
    {'title': 'Movie Ticket', 'date': '2025-04-22'},
  ];

  @override
  Widget build(BuildContext context) {
    List<Widget> items = [];
    if (filter == 'All' || filter == 'Habits') {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Completed Habits',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      items.addAll(
        completedHabits.map(
          (habit) => ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(habit['title']),
            subtitle: Text('Completed on ${habit['date']}'),
          ),
        ),
      );
    }
    if (filter == 'All' || filter == 'Rewards') {
      items.add(
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'Purchased Rewards',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      items.addAll(
        purchasedRewards.map(
          (reward) => ListTile(
            leading: const Icon(Icons.card_giftcard, color: Colors.orange),
            title: Text(reward['title']),
            subtitle: Text('Purchased on ${reward['date']}'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: filter == 'All',
                  onSelected: (_) => setState(() => filter = 'All'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Habits'),
                  selected: filter == 'Habits',
                  onSelected: (_) => setState(() => filter = 'Habits'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Rewards'),
                  selected: filter == 'Rewards',
                  onSelected: (_) => setState(() => filter = 'Rewards'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}
