import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  spreadRadius: 0,
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
                            task.title,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: progressColor,
                              decoration: task.isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                            ),
                          ),
                          Text(
                            task.category,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: progressColor.withOpacity(0.7),
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
                            color: progressColor.withOpacity(0.7),
                          ),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red[300],
                          ),
                          onPressed: onDelete,
                        ),
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 300),
                          tween: Tween<double>(
                            begin: 0,
                            end: task.isCompleted ? 1 : 0,
                          ),
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: 0.8 + (value * 0.2),
                              child: IconButton(
                                onPressed: onToggleComplete,
                                icon: Icon(
                                  Icons.check_circle,
                                  color: Color.lerp(
                                    progressColor.withOpacity(0.3),
                                    progressColor,
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
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.description,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: progressColor.withOpacity(0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _getCategoryIcon(task.category),
                      size: 16,
                      color: progressColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, y').format(task.dueDate),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: progressColor.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    if (task.dueTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: progressColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTimeOfDay(task.dueTime!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: progressColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: getPriorityColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.priority,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: getPriorityColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'personal':
        return Icons.person_outline;
      case 'work':
        return Icons.work_outline;
      case 'shopping':
        return Icons.shopping_bag_outlined;
      case 'health':
        return Icons.favorite_outline;
      default:
        return Icons.category_outlined;
    }
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Color getPriorityColor() {
    switch (task.priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}