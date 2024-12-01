import 'package:flutter/material.dart';
import '../models/habit.dart';
import '../models/task.dart';
import 'stat_card.dart';

class DashboardStats extends StatelessWidget {
  final List<Habit> habits;
  final List<Task> tasks;
  final Function(int) onNavigate;

  const DashboardStats({
    Key? key,
    required this.habits,
    required this.tasks,
    required this.onNavigate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 52) / 2;

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

    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: cardWidth,
            height: cardWidth * 0.7,
            child: InkWell(
              onTap: () => onNavigate(1), // Navigate to Habits tab
              borderRadius: BorderRadius.circular(16),
              child: StatCard(
                title: 'Habits',
                value: '$completedHabits/$totalHabits',
                icon: Icons.track_changes_outlined,
                progress: habitProgress,
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: cardWidth,
            height: cardWidth * 0.7,
            child: InkWell(
              onTap: () => onNavigate(2), // Navigate to Tasks tab
              borderRadius: BorderRadius.circular(16),
              child: StatCard(
                title: 'Tasks',
                value: totalTasks > 0 ? '$completedTasks/$totalTasks' : 'All clear today',
                icon: Icons.task_outlined,
                progress: taskProgress,
              ),
            ),
          ),
        ],
      ),
    );
  }
}