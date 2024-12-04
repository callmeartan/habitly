import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';

class StreakOverview extends StatefulWidget {
  final List<Habit> habits;

  const StreakOverview({
    Key? key,
    required this.habits,
  }) : super(key: key);

  @override
  _StreakOverviewState createState() => _StreakOverviewState();
}

class _StreakOverviewState extends State<StreakOverview> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _progressAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (widget.habits.isEmpty) {
      return const SizedBox.shrink();
    }

    final limitedHabits = widget.habits.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Streak Overview',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          _buildStreakItem(
            'Overall',
            _calculateOverallStreak(),
            isDark,
          ),
          const SizedBox(height: 16),
          ...limitedHabits.map((habit) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildStreakItem(
              habit.name,
              habit.streak,
              isDark,
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildStreakItem(
    String label,
    int days,
    bool isDark,
  ) {
    final progressColor = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: progressColor,
              ),
            ),
            Text(
              '$days days',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: progressColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (_progressAnimation.value * days) / 30, // Max 30 days
                backgroundColor: progressColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 8,
              ),
            );
          },
        ),
      ],
    );
  }

  int _calculateOverallStreak() {
    if (widget.habits.isEmpty) return 0;
    final totalStreak = widget.habits.fold<int>(
      0,
      (sum, habit) => sum + habit.streak,
    );
    return (totalStreak / widget.habits.length).round();
  }
} 