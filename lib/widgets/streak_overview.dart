import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';

class StreakOverview extends StatelessWidget {
  final List<Habit> habits;

  const StreakOverview({
    Key? key,
    required this.habits,
  }) : super(key: key);

  int _calculateOverallStreak() {
    if (habits.isEmpty) return 0;
    final totalStreak = habits.fold<int>(
      0,
      (sum, habit) => sum + habit.streak,
    );
    return (totalStreak / habits.length).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (habits.isEmpty) {
      return const SizedBox.shrink();
    }

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
          ...habits.map((habit) => Padding(
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
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: days / 30, // Max 30 days
            backgroundColor: progressColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
} 