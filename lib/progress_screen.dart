import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'services/firestore_service.dart';
import 'models/goal.dart';
import 'models/progress_log.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Center(child: Text('Not signed in'));
    final firestore = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Habit Consistency (Last 7 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: StreamBuilder<List<ProgressLog>>(
                  stream: firestore.progressLogsStream(user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final logs = snapshot.data!;
                    // Group by day for the last 7 days
                    final now = DateTime.now();
                    final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));
                    final counts = List.generate(7, (i) => logs.where((log) => log.date.year == days[i].year && log.date.month == days[i].month && log.date.day == days[i].day).length);
                    return BarChart(
                      BarChartData(
                        barGroups: List.generate(7, (i) => BarChartGroupData(x: i, barRods: [BarChartRodData(toY: counts[i].toDouble(), color: Colors.blue)])),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx > 6) return const SizedBox();
                                final d = days[idx];
                                return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Points Trend (Last 14 Days)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(
                height: 200,
                child: StreamBuilder<List<ProgressLog>>(
                  stream: firestore.progressLogsStream(user.uid),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final logs = snapshot.data!;
                    final now = DateTime.now();
                    final days = List.generate(14, (i) => now.subtract(Duration(days: 13 - i)));
                    final points = List.generate(14, (i) => logs.where((log) => log.date.year == days[i].year && log.date.month == days[i].month && log.date.day == days[i].day).fold<int>(0, (sum, log) => sum + log.pointsEarned));
                    return LineChart(
                      LineChartData(
                        lineBarsData: [
                          LineChartBarData(
                            spots: List.generate(14, (i) => FlSpot(i.toDouble(), points[i].toDouble())),
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            dotData: FlDotData(show: false),
                          ),
                        ],
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx > 13) return const SizedBox();
                                final d = days[idx];
                                return Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10));
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              const Text('Goal Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              StreamBuilder<List<Goal>>(
                stream: firestore.goalsStream(user.uid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final goals = snapshot.data!;
                  if (goals.isEmpty) return const Text('No goals yet.');
                  return Column(
                    children: goals.map((goal) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(goal.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (goal.progress / 100).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: Colors.grey[300],
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(height: 2),
                          Text('${goal.progress}% complete', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    )).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
