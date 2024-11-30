import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../screens/task_calendar_screen.dart';

class DashboardCalendar extends StatelessWidget {
  final List<Task> tasks;
  final DateTime selectedDate;
  final Function(DateTime) onDateSelected;

  const DashboardCalendar({
    Key? key,
    required this.tasks,
    required this.selectedDate,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Calculate the start of the week (Monday)
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Weekday labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
              return SizedBox(
                width: 40,
                child: Text(
                  day,
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Calendar days
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final date = startOfWeek.add(Duration(days: index));
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());
              final activeTasks = _getActiveTasksForDate(date);

              // Get highest priority task for the day
              String highestPriority = 'low';
              if (activeTasks.isNotEmpty) {
                if (activeTasks.any((task) => task.priority.toLowerCase() == 'high')) {
                  highestPriority = 'high';
                } else if (activeTasks.any((task) => task.priority.toLowerCase() == 'medium')) {
                  highestPriority = 'medium';
                }
              }

              // Determine the background color
              Color? backgroundColor;
              if (isSelected) {
                backgroundColor = colorScheme.primary;
              } else if (activeTasks.isNotEmpty) {
                backgroundColor = _getPriorityColor(highestPriority).withOpacity(0.2);
              } else if (isToday) {
                backgroundColor = colorScheme.primary.withOpacity(0.1);
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TaskCalendarScreen(
                        tasks: tasks,
                        onTaskAdded: (Task newTask) {
                          // Handle adding the new task
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      date.day.toString(),
                      style: GoogleFonts.poppins(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: isSelected || isToday
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.yellow;
      case 'low':
      default:
        return Colors.green;
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _getActiveTasksForDate(DateTime date) {
    return tasks.where((task) =>
    _isSameDay(task.dueDate, date) &&
        !task.isCompleted // Only include tasks that aren't completed
    ).toList();
  }
}