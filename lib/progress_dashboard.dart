import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';

class ProgressDashboard extends StatelessWidget {
  const ProgressDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserPointsSummary(),
            const SizedBox(height: 24),
            const Text(
              'Habit Consistency',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 200, child: _HabitConsistencyBarChart()),
            const SizedBox(height: 32),
            const Text(
              'Points Trend',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 200, child: _PointsTrendLineChart()),
            const SizedBox(height: 32),
            const Text(
              'Goal Progress',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            _GoalProgressList(),
          ],
        ),
      ),
    );
  }
}

class _UserPointsSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder for user points summary
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Your Points',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '1200',
              style: TextStyle(fontSize: 18, color: Colors.green[700]),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitConsistencyBarChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder bar chart
    return BarChart(
      BarChartData(
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [BarChartRodData(toY: 5, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [BarChartRodData(toY: 3, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [BarChartRodData(toY: 4, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [BarChartRodData(toY: 2, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [BarChartRodData(toY: 6, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 5,
            barRods: [BarChartRodData(toY: 1, color: Colors.blue)],
          ),
          BarChartGroupData(
            x: 6,
            barRods: [BarChartRodData(toY: 7, color: Colors.blue)],
          ),
        ],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _PointsTrendLineChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder line chart
    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: [
              FlSpot(0, 10),
              FlSpot(1, 12),
              FlSpot(2, 15),
              FlSpot(3, 13),
              FlSpot(4, 18),
              FlSpot(5, 17),
              FlSpot(6, 20),
            ],
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
      ),
    );
  }
}

class _GoalProgressList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Placeholder for 3 goals
    final goals = [
      {'title': 'Read 10 books', 'progress': 0.7},
      {'title': 'Run 100 km', 'progress': 0.45},
      {'title': 'Meditate 30 days', 'progress': 0.9},
    ];
    return Column(
      children:
          goals
              .map(
                (goal) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['title'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      SizedBox(
                        height: 16,
                        child: LinearProgressIndicator(
                          value: goal['progress'] as double,
                          backgroundColor: Colors.grey[300],
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}
