import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/habit.dart';
import '../providers/theme_provider.dart';
import '../repositories/habit_repository.dart';
import '../services/notification_service.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form.dart';
import '../widgets/stat_card.dart';
import '../widgets/empty_habits.dart';

class HabitDashboard extends StatefulWidget {
  const HabitDashboard({Key? key}) : super(key: key);

  @override
  _HabitDashboardState createState() => _HabitDashboardState();
}

class _HabitDashboardState extends State<HabitDashboard> {
  final _habitRepository = HabitRepository();
  final NotificationService _notificationService = NotificationService();
  List<Habit> habits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final loadedHabits = await _habitRepository.loadHabits();

      setState(() {
        habits = loadedHabits.isEmpty
            ? [
                Habit(
                  id: 1,
                  name: 'Morning Meditation',
                  category: 'Health',
                  streak: 5,
                  frequency: 'daily',
                  completedToday: false,
                  progress: 0.85,
                  reminderTime: null,
                ),
                Habit(
                  id: 2,
                  name: 'Read 30 Minutes',
                  category: 'Personal Development',
                  streak: 12,
                  frequency: 'daily',
                  completedToday: true,
                  progress: 0.92,
                  reminderTime: null,
                ),
                Habit(
                  id: 3,
                  name: 'Weekly Exercise',
                  category: 'Health',
                  streak: 3,
                  frequency: 'weekly',
                  completedToday: false,
                  progress: 0.75,
                  reminderTime: null,
                ),
              ]
            : loadedHabits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load habits: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _scheduleReminder(Habit habit) async {
    if (habit.reminderTime == null) {
      return;
    }

    try {
      await _notificationService.cancelReminder(habit.id);
      final now = DateTime.now();

      final scheduledTime = DateTime(
        now.year,
        now.month,
        now.day,
        habit.reminderTime!.hour,
        habit.reminderTime!.minute,
      );

      final finalScheduledTime = scheduledTime.isBefore(now)
          ? scheduledTime.add(const Duration(days: 1))
          : scheduledTime;

      await _notificationService.scheduleHabitReminder(
        id: habit.id,
        habitName: habit.name,
        scheduledTime: finalScheduledTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reminder set for ${habit.name} at ${_formatTime(finalScheduledTime)}',
              style: GoogleFonts.poppins(),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to set reminder: ${e.toString()}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void toggleHabitCompletion(int habitId) async {
    setState(() {
      final habitIndex = habits.indexWhere((h) => h.id == habitId);
      if (habitIndex != -1) {
        final habit = habits[habitIndex];
        final isCompleting = !habit.completedToday;

        // Get current date without time
        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        List<DateTime> updatedCompletionDates =
            List<DateTime>.from(habit.completionDates);

        if (isCompleting) {
          // Only add if the date isn't already in the list
          if (!updatedCompletionDates.any((date) =>
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day)) {
            updatedCompletionDates.add(today);
          }
        } else {
          // Remove if exists
          updatedCompletionDates.removeWhere((date) =>
              date.year == today.year &&
              date.month == today.month &&
              date.day == today.day);
        }

        // Calculate streak
        final newStreak = isCompleting ? habit.streak + 1 : habit.streak - 1;

        habits[habitIndex] = habit.copyWith(
          completedToday: isCompleting,
          progress: isCompleting ? 1.0 : 0.0,
          completionDates: updatedCompletionDates,
          streak: newStreak >= 0 ? newStreak : 0,
        );

        // Debug print to verify dates
        print(
            'Completion dates for ${habit.name}: ${habits[habitIndex].completionDates}');
      }
    });
    await _habitRepository.saveHabits(habits);
  }

  Future<void> _deleteHabit(int habitId) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Habit',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Are you sure you want to delete this habit?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                await _notificationService.cancelReminder(habitId);
                setState(() {
                  habits.removeWhere((habit) => habit.id == habitId);
                });
                await _habitRepository.saveHabits(habits);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Habit deleted successfully')),
                );
              },
              child: Text(
                'Delete',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete habit: $e')),
      );
    }
  }

  Future<void> _editHabit(Habit habit) async {
    final formKey = GlobalKey<FormState>();
    String name = habit.name;
    String category = habit.category;
    String frequency = habit.frequency;
    DateTime? reminderTime = habit.reminderTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Edit Habit',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: HabitForm(
            initialName: name,
            initialCategory: category,
            initialFrequency: frequency,
            initialReminderTime: reminderTime,
            onNameChanged: (value) => name = value,
            onCategoryChanged: (value) => category = value ?? category,
            onFrequencyChanged: (value) => frequency = value ?? frequency,
            onReminderTimeChanged: (value) => reminderTime = value,
            formKey: formKey,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    final habitIndex =
                        habits.indexWhere((h) => h.id == habit.id);
                    if (habitIndex != -1) {
                      habits[habitIndex] = habit.copyWith(
                        name: name,
                        category: category,
                        frequency: frequency,
                        reminderTime: reminderTime,
                      );
                    }
                  });
                  await _habitRepository.saveHabits(habits);

                  if (reminderTime != habit.reminderTime) {
                    if (habit.reminderTime != null) {
                      await _notificationService.cancelReminder(habit.id);
                    }
                    if (reminderTime != null) {
                      final habitIndex =
                          habits.indexWhere((h) => h.id == habit.id);
                      await _scheduleReminder(habits[habitIndex]);
                    }
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Habit updated successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              child: Text(
                'Save Changes',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddHabitDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String category = 'Health';
    String frequency = 'daily';
    DateTime? reminderTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add New Habit',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: HabitForm(
            initialName: name,
            initialCategory: category,
            initialFrequency: frequency,
            initialReminderTime: reminderTime,
            onNameChanged: (value) => name = value,
            onCategoryChanged: (value) => category = value ?? category,
            onFrequencyChanged: (value) => frequency = value ?? frequency,
            onReminderTimeChanged: (value) => reminderTime = value,
            formKey: formKey,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newHabit = Habit(
                    id: habits.isEmpty
                        ? 1
                        : habits.map((h) => h.id).reduce(max) + 1,
                    name: name,
                    category: category,
                    streak: 0,
                    frequency: frequency,
                    completedToday: false,
                    progress: 0.0,
                    reminderTime: reminderTime,
                  );
                  setState(() {
                    habits.add(newHabit);
                  });
                  await _habitRepository.saveHabits(habits);
                  await _scheduleReminder(newHabit);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Habit added successfully')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              child: Text(
                'Add Habit',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: GoogleFonts.poppins(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadHabits,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final completedToday = habits.where((h) => h.completedToday).length;
    final averageProgress = habits.isEmpty
        ? 0.0
        : (habits.fold<double>(
              0,
              (sum, habit) => sum + habit.progress,
            ) /
            habits.length *
            100);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Habitly',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Provider.of<ThemeProvider>(context).isDarkMode
                          ? Icons.light_mode
                          : Icons.dark_mode,
                      color: colorScheme.onBackground,
                    ),
                    onPressed: () {
                      Provider.of<ThemeProvider>(context, listen: false)
                          .toggleTheme();
                    },
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddHabitDialog,
                    icon: Icon(
                      Icons.add,
                      size: 22,
                      color: Colors.black,
                    ),
                    label: Text(
                      'Add Habit',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                height: 140,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    StatCard(
                      title: 'Completed',
                      value: completedToday.toString(),
                      icon: Icons.check_circle_outline,
                    ),
                    StatCard(
                      title: 'Progress',
                      value: '${averageProgress.round()}%',
                      icon: Icons.bar_chart,
                    ),
                    StatCard(
                      title: 'Total Habits',
                      value: habits.length.toString(),
                      icon: Icons.calendar_today,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Active Habits',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onBackground,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: habits.isEmpty
                    ? const EmptyHabits()
                    : ListView.builder(
                        itemCount: habits.length,
                        itemBuilder: (context, index) {
                          final habit = habits[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: HabitCard(
                              habit: habit,
                              onEdit: () => _editHabit(habit),
                              onDelete: () => _deleteHabit(habit.id),
                              onToggleCompletion: () =>
                                  toggleHabitCompletion(habit.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
