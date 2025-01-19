import 'package:flutter/material.dart';
import 'package:habitly/widgets/dashboard_calendar.dart';
import '../services/firebase_sync_service.dart';

import '../models/habit.dart';
import '../models/task.dart';
import '../repositories/habit_repository.dart';
import '../repositories/task_repository.dart';
import '../services/notification_service.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_stats.dart';
import '../widgets/error_view.dart';
import '../widgets/streak_overview.dart';
import '../providers/navigation_state.dart';
import '../widgets/taskpiechart.dart';

class HabitDashboard extends StatefulWidget {
  const HabitDashboard({Key? key}) : super(key: key);

  @override
  HabitDashboardState createState() => HabitDashboardState();
}

class HabitDashboardState extends State<HabitDashboard> {
  final HabitRepository _habitRepository = HabitRepository();
  final TaskRepository _taskRepository = TaskRepository();
  final NotificationService _notificationService = NotificationService();
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  List<Habit> habits = [];
  List<Task> _tasks = [];
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _notificationService.init();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load both habits and tasks concurrently
      await Future.wait([
        _loadHabits(),
        _loadTasks(),
      ]);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadTasks() async {
    try {
      final loadedTasks = await _taskRepository.loadTasks();
      if (mounted) {
        setState(() {
          _tasks = loadedTasks;
        });
      }
    } catch (e) {
      print('Error loading tasks: $e');
    }
  }



  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
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
            userId: _firebaseSyncService.currentUserId ?? '',
            name: 'Morning Meditation',
            category: 'Health',
            streak: 5,
            frequency: 'daily',
            completedToday: false,
            progress: 0.85,
            reminderTime: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
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



  void toggleHabitCompletion(int habitId) async {
    setState(() {
      final habitIndex = habits.indexWhere((h) => h.id == habitId);
      if (habitIndex != -1) {
        final habit = habits[habitIndex];
        final isCompleting = !habit.completedToday;

        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        List<DateTime> updatedCompletionDates =
        List<DateTime>.from(habit.completionDates);

        if (isCompleting) {
          if (!updatedCompletionDates.any((date) =>
          date.year == today.year &&
              date.month == today.month &&
              date.day == today.day)) {
            updatedCompletionDates.add(today);
          }
        } else {
          updatedCompletionDates.removeWhere((date) =>
          date.year == today.year &&
              date.month == today.month &&
              date.day == today.day);
        }

        final newStreak = isCompleting ? habit.streak + 1 : habit.streak - 1;

        habits[habitIndex] = habit.copyWith(
          completedToday: isCompleting,
          progress: isCompleting ? 1.0 : 0.0,
          completionDates: updatedCompletionDates,
          streak: newStreak >= 0 ? newStreak : 0,
        );
      }
    });
    await _habitRepository.saveHabits(habits);
  }



  void refreshDashboard() {
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {


    if (_error != null) {
      return ErrorView(
        error: _error!,
        onRetry: _loadHabits,
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DashboardHeader(),
                    const SizedBox(height: 16),
                    DashboardCalendar(
                      tasks: _tasks,
                      selectedDate: _selectedDate,
                      onDateSelected: _onDateSelected,
                    ),
                    const SizedBox(height: 16),
                    DashboardStats(
                      habits: habits,
                      tasks: _tasks,
                      onNavigate: (index) {
                        if (context.mounted) {
                          NavigationState.of(context)?.onNavigate(index);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    StreakOverview(habits: habits),
                    const SizedBox(height: 16),
                    TaskPieChart(
                      tasks: _tasks,
                      selectedMonth: DateTime.now(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
