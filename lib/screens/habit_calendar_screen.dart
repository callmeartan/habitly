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
  }

  void _initializeCompletionMap() {
    _completionMap = {};
    for (final date in widget.habit.completionDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);
      _completionMap[normalizedDate] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.habit.name,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Calendar View',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onPrimary.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
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
              markersAnchor: 1.5,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final normalizedDate = DateTime(date.year, date.month, date.day);
                if (_completionMap[normalizedDate] == true) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorScheme.primary.withOpacity(0.8),
                    ),
                    width: 42,
                    height: 42,
                    child: Center(
                      child: Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Statistics',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          'Current Streak',
                          _calculateCurrentStreak().toString(),
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                        _buildStatItem(
                          'Best Streak',
                          _calculateBestStreak().toString(),
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                        _buildStatItem(
                          'Total Days',
                          widget.habit.completionDates.length.toString(),
                          Icons.calendar_today,
                          Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
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
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
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