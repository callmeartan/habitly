import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';

class HabitCalendarScreen extends StatefulWidget {
  final Habit habit;

  const HabitCalendarScreen({
    Key? key,
    required this.habit,
  }) : super(key: key);

  @override
  _HabitCalendarScreenState createState() => _HabitCalendarScreenState();
}

class _HabitCalendarScreenState extends State<HabitCalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late Map<DateTime, bool> _completionMap;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _initializeCompletionMap();
    print('Completion dates in initState: ${widget.habit.completionDates}');
  }

  void _initializeCompletionMap() {
    _completionMap = {};
    for (final date in widget.habit.completionDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _completionMap[normalizedDate] = true;
      print('Adding date to completion map: $normalizedDate');
    }
  }

  bool _isDateCompleted(DateTime date) {
    final normalizedDate = DateTime(date.year, date.month, date.day);
    return widget.habit.completionDates.any((completionDate) {
      final normalizedCompletionDate = DateTime(
        completionDate.year,
        completionDate.month,
        completionDate.day,
      );
      return normalizedCompletionDate.isAtSameMomentAs(normalizedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.habit.name,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.primaryTextTheme.titleLarge?.color,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.primaryTextTheme.titleLarge?.color?.withAlpha(204),
                ),
                const SizedBox(width: 4),
                Text(
                  'Progress Tracker',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.primaryTextTheme.titleLarge?.color?.withAlpha(204),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    weekendTextStyle: TextStyle(color: colorScheme.onSurface),
                    holidayTextStyle: TextStyle(color: colorScheme.onSurface),
                    selectedDecoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: colorScheme.primary.withAlpha(128),
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (_isDateCompleted(date)) {
                        return Center(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.primary,
                            ),
                            width: 35,
                            height: 35,
                            child: Center(
                              child: Text(
                                date.day.toString(),
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  headerStyle: HeaderStyle(
                    titleTextStyle: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                    formatButtonDecoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Your Progress',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.insights,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Streak',
                        _calculateCurrentStreak().toString(),
                        Icons.local_fire_department,
                        theme,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Best Streak',
                        _calculateBestStreak().toString(),
                        Icons.emoji_events,
                        theme,
                        Colors.amber,
                      ),
                      _buildStatCard(
                        'Total Days',
                        widget.habit.completionDates.length.toString(),
                        Icons.calendar_today,
                        theme,
                        Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      ThemeData theme,
      Color color,
      ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  int _calculateCurrentStreak() {
    if (widget.habit.completionDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(widget.habit.completionDates)
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    DateTime currentDate = sortedDates[0];

    for (int i = 1; i < sortedDates.length; i++) {
      final difference = currentDate.difference(sortedDates[i]).inDays;
      if (difference == 1) {
        streak++;
        currentDate = sortedDates[i];
      } else {
        break;
      }
    }

    // Check if the streak is still active (includes today or yesterday)
    final today = DateTime.now();
    final latestDate = sortedDates[0];
    final daysSinceLatest = today.difference(latestDate).inDays;

    if (daysSinceLatest > 1) {
      return 0; // Streak is broken if more than 1 day has passed
    }

    return streak;
  }

  int _calculateBestStreak() {
    if (widget.habit.completionDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(widget.habit.completionDates)
      ..sort((a, b) => a.compareTo(b));

    int currentStreak = 1;
    int bestStreak = 1;
    DateTime currentDate = sortedDates[0];

    for (int i = 1; i < sortedDates.length; i++) {
      final difference = sortedDates[i].difference(currentDate).inDays;
      if (difference == 1) {
        currentStreak++;
        bestStreak = currentStreak > bestStreak ? currentStreak : bestStreak;
      } else {
        currentStreak = 1;
      }
      currentDate = sortedDates[i];
    }

    return bestStreak;
  }
}