import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../screens/habit_calendar_screen.dart';

class HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleCompletion;

  const HabitCard({
    Key? key,
    required this.habit,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCompletion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HabitCalendarScreen(habit: habit),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        habit.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        habit.category,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        size: 20,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red[300]
                      ),
                      onPressed: onDelete,
                    ),
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(
                        begin: 0,
                        end: habit.completedToday ? 1 : 0,
                      ),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: IconButton(
                            onPressed: onToggleCompletion,
                            icon: Icon(
                              Icons.check_circle,
                              color: Color.lerp(
                                colorScheme.onSurface.withOpacity(0.3),
                                Colors.green,
                                value,
                              ),
                              size: 32,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 16,
                  color: Colors.amber[400],
                ),
                const SizedBox(width: 4),
                Text(
                  'Streak: ${habit.streak} days',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const Spacer(),
                if (habit.reminderTime != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(habit.reminderTime!),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 8),
                Text(
                  habit.frequency,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0, end: habit.progress),
              builder: (context, double value, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: value,
                    backgroundColor: colorScheme.onSurface.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 8,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}