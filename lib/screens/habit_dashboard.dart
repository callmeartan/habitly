import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../widgets/habit_form.dart';
import '../widgets/habit_card.dart';
import '../widgets/task_form.dart';
import '../widgets/streak_overview.dart';
import '../providers/navigation_state.dart';

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

  Future<void> _scheduleReminder(Habit habit) async {
    if (habit.reminderTime == null) return;

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
    } catch (e) {
      print('Failed to set reminder: $e');
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

  Future<void> _deleteHabit(int habitId) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Delete Habit',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
      print('Failed to delete habit: $e');
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
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 16,
                ),
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
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Future<void> _showAddTaskDialog() async {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    String category = 'Personal';
    String priority = 'Medium';
    DateTime? dueDate;
    TimeOfDay? dueTime;
    DateTime? reminder;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Add New Task',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: TaskForm(
            initialTitle: title,
            initialDescription: description,
            initialCategory: category,
            initialPriority: priority,
            initialDueDate: dueDate,
            initialDueTime: dueTime,
            initialReminder: reminder,
            onTitleChanged: (value) => title = value,
            onDescriptionChanged: (value) => description = value,
            onCategoryChanged: (value) => category = value ?? category,
            onPriorityChanged: (value) => priority = value ?? priority,
            onDueDateChanged: (value) => dueDate = value,
            onDueTimeChanged: (value) => dueTime = value,
            onReminderChanged: (value) => reminder = value,
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
                if (formKey.currentState!.validate() && dueDate != null) {
                  try {
                    final tasks = await _taskRepository.loadTasks();
                    final newTaskId = tasks.isEmpty
                        ? 1
                        : tasks.map((t) => t.id).reduce(max) + 1;

                    final newTask = Task(
                      id: newTaskId,
                      title: title,
                      description: description,
                      category: category,
                      priority: priority,
                      dueDate: dueDate!,
                      dueTime: dueTime,
                      reminder: reminder,
                    );

                    await _taskRepository.addTask(newTask);

                    if (reminder != null) {
                      await _notificationService.scheduleTaskReminder(
                        id: newTaskId + 10000,
                        taskTitle: title,
                        scheduledTime: reminder,
                      );
                    }

                    if (!mounted) return;
                    Navigator.pop(context);
                  } catch (e) {
                    print('Failed to add task: $e');
                  }
                } else if (dueDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please set a due date')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
              ),
              child: Text(
                'Add Task',
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
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
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
                    userId: _firebaseSyncService.currentUserId ?? '',
                    name: name,
                    category: category,
                    streak: 0,
                    frequency: frequency,
                    completedToday: false,
                    progress: 0.0,
                    reminderTime: reminderTime,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  setState(() {
                    habits.add(newHabit);
                  });
                  await _habitRepository.saveHabits(habits);
                  await _scheduleReminder(newHabit);
                  Navigator.pop(context);
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

  void _refreshDashboard() async {
    await Future.wait([
      _loadHabits(),
      _loadTasks(),
    ]);
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
