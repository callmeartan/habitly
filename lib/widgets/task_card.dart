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
    final colorScheme = theme.colorScheme;

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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(task.category),
                    size: 20,
                    color: colorScheme.primary.withOpacity(0.8),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    task.category,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: getPriorityColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: getPriorityColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          task.priority,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: getPriorityColor(),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
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
                            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                            color: task.isCompleted
                                ? colorScheme.onSurface.withOpacity(0.5)
                                : colorScheme.onSurface,
                          ),
                        ),
                        if (task.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            task.description,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 300),
                    tween: Tween<double>(
                      begin: 0,
                      end: task.isCompleted ? 1 : 0,
                    ),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(
                                colorScheme.outline,
                                Colors.green,
                                value,
                              )!,
                              width: 2,
                            ),
                            color: Color.lerp(
                              Colors.transparent,
                              Colors.green.withOpacity(0.1),
                              value,
                            ),
                          ),
                          child: IconButton(
                            onPressed: onToggleComplete,
                            icon: Icon(
                              Icons.check,
                              color: Color.lerp(
                                colorScheme.outline,
                                Colors.green,
                                value,
                              ),
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d, y').format(task.dueDate),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: colorScheme.primary,
                    ),
                  ),
                  if (task.dueTime != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTimeOfDay(task.dueTime!),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                  if (task.reminder != null) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.notifications_outlined,
                      size: 16,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Reminder set',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.secondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    onPressed: onDelete,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
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
}