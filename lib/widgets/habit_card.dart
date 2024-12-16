import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../screens/habit_calendar_screen.dart';

class HabitCard extends StatefulWidget {
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
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: widget.habit.progress,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _progressController.forward();
  }

  @override
  void didUpdateWidget(HabitCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.habit.progress != widget.habit.progress) {
      _progressAnimation = Tween<double>(
        begin: oldWidget.habit.progress,
        end: widget.habit.progress,
      ).animate(CurvedAnimation(
        parent: _progressController,
        curve: Curves.easeInOut,
      ));
      _progressController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressColor = isDark ? Colors.white : Colors.black;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HabitCalendarScreen(habit: widget.habit),
            ),
          );
        },
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
                            widget.habit.name,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            widget.habit.category,
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
                            end: widget.habit.completedToday ? 1 : 0,
                          ),
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: 0.8 + (value * 0.2),
                              child: IconButton(
                                onPressed: widget.onToggleCompletion,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.emoji_events,
                      size: 16,
                      color: progressColor.withOpacity(0.7),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Streak: ${widget.habit.getCurrentStreak()} days',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: progressColor.withOpacity(0.7),
                      ),
                    ),
                    const Spacer(),
                    if (widget.habit.reminderTime != null)
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: progressColor.withOpacity(0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(widget.habit.reminderTime!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: progressColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(width: 8),
                    Text(
                      widget.habit.frequency,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: progressColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedBuilder(
                  animation: _progressAnimation,
                  builder: (context, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _progressAnimation.value,
                        backgroundColor: progressColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                        minHeight: 8,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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