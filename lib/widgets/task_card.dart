import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatefulWidget {
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
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  String _getRepetitionText(Task task) {
    if (task.repeatMode == null) return '';

    final interval = task.repeatInterval ?? 1;
    final intervalText = interval > 1 ? ' $interval' : '';

    switch (task.repeatMode) {
      case 'daily':
        return 'Repeats$intervalText daily';
      case 'weekly':
        if (task.repeatDays?.isNotEmpty ?? false) {
          final days = task.repeatDays!
              .map((day) => _getWeekdayShort(day))
              .join(', ');
          return 'Repeats on $days';
        }
        return 'Repeats$intervalText weekly';
      case 'monthly':
        return 'Repeats$intervalText monthly';
      case 'yearly':
        return 'Repeats$intervalText yearly';
      default:
        return '';
    }
  }

  String _getWeekdayShort(int day) {
    switch (day) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final task = widget.task;
    
    final progressColor = task.isCompleted
        ? colorScheme.onSurface.withOpacity(0.5)
        : colorScheme.onSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onEdit,
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
                          onPressed: widget.onEdit,
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 20,
                            color: Colors.red[300],
                          ),
                          onPressed: widget.onDelete,
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
                                onPressed: widget.onToggleComplete,
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
                    if (task.dueTime != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: progressColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTime(task.dueTime!),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: progressColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        task.priority,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: _getPriorityColor(task.priority),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                if (task.repeatMode != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.repeat,
                        size: 16,
                        color: progressColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _getRepetitionText(task),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: progressColor.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      if (task.repeatUntil != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          'Until ${DateFormat('MMM d').format(task.repeatUntil!)}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: progressColor.withOpacity(0.7),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                if (task.reminder != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.notifications_outlined,
                        size: 16,
                        color: progressColor.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Reminder: ${DateFormat('MMM d, HH:mm').format(task.reminder!)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: progressColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
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

  String _formatTime(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }
}