import 'package:flutter/material.dart';
import '../models/habit.dart';
import 'stat_card.dart';

class DashboardStats extends StatelessWidget {
  final List<Habit> habits;

  const DashboardStats({
    Key? key,
    required this.habits,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedToday = habits.where((h) => h.completedToday).length;
    final averageProgress = habits.isEmpty
        ? 0.0
        : (habits.fold<double>(
      0,
          (sum, habit) => sum + habit.progress,
    ) /
        habits.length *
        100);

    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          StatCard(
            title: 'Completed',
            value: completedToday.toString(),
            icon: Icons.check_circle_outline,
          ),
          StatCard(
            title: 'Progress',
            value: '${averageProgress.round()}%',
            icon: Icons.bar_chart,
          ),
          StatCard(
            title: 'Total Habits',
            value: habits.length.toString(),
            icon: Icons.calendar_today,
          ),
        ],
      ),
    );
  }
}