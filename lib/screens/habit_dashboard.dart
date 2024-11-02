// lib/screens/habit_dashboard.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form.dart';
import '../repositories/habit_repository.dart';
import '../services/notification_service.dart';
import 'dart:math' show max;
import '../providers/theme_provider.dart';  // Add this line
import 'package:provider/provider.dart';  // Add this line

import 'package:shared_preferences/shared_preferences.dart';


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
        habits = loadedHabits.isEmpty ? [
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
        ] : loadedHabits;
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
    if (habit.reminderTime != null) {
      await _notificationService.scheduleHabitReminder(
        id: habit.id,
        habitName: habit.name,
        scheduledTime: habit.reminderTime!,
      );
    }
  }

  void toggleHabitCompletion(int habitId) async {
    setState(() {
      final habitIndex = habits.indexWhere((h) => h.id == habitId);
      if (habitIndex != -1) {
        final habit = habits[habitIndex];
        habits[habitIndex] = habit.copyWith(
          completedToday: !habit.completedToday,
          progress: !habit.completedToday ? 1.0 : 0.0,
        );
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
                    final habitIndex = habits.indexWhere((h) => h.id == habit.id);
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
                      final habitIndex = habits.indexWhere((h) => h.id == habit.id);
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
                    id: habits.isEmpty ? 1 : habits.map((h) => h.id).reduce(max) + 1,
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

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                icon,
                color: Colors.grey[600],
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
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
      // Use theme background color instead of hardcoded Colors.grey[100]
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row with App Title, Theme Toggle, and Add Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Title
                  Expanded(
                    child: Text(
                      'Habitly',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        // Use theme color for text instead of hardcoded color
                        color: colorScheme.onBackground,
                      ),
                    ),
                  ),
                  // Theme Toggle Button
                  IconButton(
                    icon: Icon(
                      // Change icon based on current theme
                      Provider.of<ThemeProvider>(context).isDarkMode
                          ? Icons.light_mode  // Show sun icon in dark mode
                          : Icons.dark_mode,  // Show moon icon in light mode
                      color: colorScheme.onBackground,
                    ),
                    onPressed: () {
                      // Toggle between light and dark theme
                      Provider.of<ThemeProvider>(context, listen: false).toggleTheme();                    },
                  ),
                  const SizedBox(width: 8),
                  // Add Habit Button
                  ElevatedButton.icon(
                    onPressed: _showAddHabitDialog,
                    icon: const Icon(Icons.add, size: 22),
                    label: Text(
                      'Add Habit',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      // Use theme colors for button
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
                    _buildStatCard(
                      'Total Habits',
                      habits.length.toString(),
                      Icons.calendar_today,
                    ),
                    _buildStatCard(
                      'Completed Today',
                      completedToday.toString(),
                      Icons.check_circle_outline,
                    ),
                    _buildStatCard(
                      'Average Progress',
                      '${averageProgress.round()}%',
                      Icons.bar_chart,
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
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: habits.isEmpty
                                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No habits yet',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add a new habit to get started',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
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