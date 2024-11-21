import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/task.dart';
import 'stat_card.dart';

class DashboardStats extends StatelessWidget {
  final List<Habit> habits;
  final List<Task> tasks;

  const DashboardStats({
    Key? key,
    required this.habits,
    required this.tasks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();

    // Calculate tasks stats
    final todaysTasks = tasks.where((task) {
      final taskDate = DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
      final compareDate = DateTime(today.year, today.month, today.day);
      return taskDate.isAtSameMomentAs(compareDate);
    }).toList();

    final completedTasks = todaysTasks.where((t) => t.isCompleted).length;
    final totalTasks = todaysTasks.length;
    final taskProgress = totalTasks > 0 ? (completedTasks / totalTasks * 100) : null;

    // Calculate habits stats
    final completedHabits = habits.where((h) => h.completedToday).length;
    final totalHabits = habits.length;
    final habitProgress = totalHabits > 0 ? (completedHabits / totalHabits * 100) : null;

    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          StatCard(
            title: 'Habits',
            value: '$completedHabits/$totalHabits',
            icon: Icons.track_changes_outlined,
            progress: habitProgress,
          ),
          StatCard(
            title: 'Tasks',
            value: totalTasks > 0 ? '$completedTasks/$totalTasks' : 'All clear today',
            icon: Icons.task_outlined,
            progress: taskProgress,
          ),
        ],
      ),
    );
  }
}