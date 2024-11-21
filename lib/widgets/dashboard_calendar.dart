import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';

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
              final tasksForDay = _getTasksForDate(date);
              final hasHighPriorityTask = tasksForDay.any(
                      (task) => task.priority.toLowerCase() == 'high'
              );

              return GestureDetector(
                onTap: () => onDateSelected(date),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : (isToday ? colorScheme.primary.withOpacity(0.1) : null),
                    shape: BoxShape.circle,
                    border: hasHighPriorityTask && !isSelected
                        ? Border.all(color: Colors.red, width: 2)
                        : null,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
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
                      if (tasksForDay.isNotEmpty && !isSelected)
                        Positioned(
                          bottom: 2,
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: hasHighPriorityTask
                                  ? Colors.red
                                  : colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<Task> _getTasksForDate(DateTime date) {
    return tasks.where((task) => _isSameDay(task.dueDate, date)).toList();
  }
}