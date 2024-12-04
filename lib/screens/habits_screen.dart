import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../repositories/habit_repository.dart';
import '/widgets/habit_form.dart';
import '../widgets/habit_card.dart';
import '../services/firebase_sync_service.dart';
import 'dart:math' show max;
import '../services/notification_service.dart';


class HabitsScreen extends StatefulWidget {
  final VoidCallback onHabitUpdated;

  const HabitsScreen({
    Key? key,
    required this.onHabitUpdated,
  }) : super(key: key);

  @override
  State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HabitRepository _habitRepository = HabitRepository();
  List<Habit> _habits = [];
  bool _isLoading = true;
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  String? _error;
  final NotificationService _notificationService = NotificationService();

  Future<void> _showAddHabitDialog() async {
    final formKey = GlobalKey<FormState>();
    String name = '';
    String category = 'Health';
    String frequency = 'daily';
    DateTime? reminderTime;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create New Habit',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: HabitForm(
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
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState!.validate()) {
                          try {
                            final newHabit = Habit(
                              id: _habits.isEmpty
                                  ? 1
                                  : _habits.map((h) => h.id).reduce((a, b) => max(a, b)) + 1,  // Fixed this line
                              userId: _firebaseSyncService.currentUserId ?? '',
                              name: name,
                              category: category,
                              streak: 0,
                              frequency: frequency,
                              completedToday: false,
                              progress: 0.0,
                              reminderTime: reminderTime,
                              completionDates: [],
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            // Schedule notification if reminder is set
                            if (reminderTime != null) {
                              await _notificationService.scheduleHabitReminder(
                                id: newHabit.id,
                                habitName: newHabit.name,
                                scheduledTime: reminderTime,
                              );
                            }

                            setState(() {
                              _habits.add(newHabit);
                            });
                            await _habitRepository.saveHabits(_habits);

                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Habit created successfully',
                                  style: GoogleFonts.poppins(),
                                ),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Failed to create habit: $e',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Create Habit',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    setState(() => _isLoading = true);
    try {
      final loadedHabits = await _habitRepository.loadHabits();
      setState(() {
        _habits = loadedHabits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load habits: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressColor = isDark ? Colors.white : Colors.black;

    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(progressColor),
            _buildErrorMessage(),
            _buildTabBar(theme, progressColor),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildHabitsList(_habits, progressColor),
                  _buildHabitsList(
                    _habits.where((habit) => habit.completedToday).toList(),
                    progressColor,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color progressColor) {
    final completedToday = _habits.where((h) => h.completedToday).length;
    final totalHabits = _habits.length;
    final completionRate = totalHabits > 0 ? completedToday / totalHabits : 0.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habits',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: progressColor,
                  ),
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(DateTime.now()),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: progressColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: completionRate,
                      backgroundColor: progressColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progressColor,
                      ),
                      strokeWidth: 3,
                    ),
                    Center(
                      child: Text(
                        '$completedToday/$totalHabits',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _showAddHabitDialog,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: progressColor,
                  size: 42,
                ),
                tooltip: 'Add Habit',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme, Color progressColor) {
    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: progressColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        labelColor: progressColor,
        unselectedLabelColor: progressColor.withOpacity(0.5),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildHabitsList(List<Habit> habits, Color progressColor) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 64,
              color: progressColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: progressColor.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        return HabitCard(
          habit: habit,
          onEdit: () => _editHabit(habit),
          onDelete: () => _deleteHabit(habit.id),
          onToggleCompletion: () => _toggleHabitCompletion(habit.id),
        );
      },
    );
  }

  Future<void> _toggleHabitCompletion(int habitId) async {
    try {
      final habitIndex = _habits.indexWhere((h) => h.id == habitId);
      if (habitIndex != -1) {
        final habit = _habits[habitIndex];

        // Check if habit needs reset before toggling
        if (habit.needsReset()) {
          habit.completedToday = false;
          habit.progress = 0.0;
        }

        final isCompleting = !habit.completedToday;

        final today = DateTime(
          DateTime.now().year,
          DateTime.now().month,
          DateTime.now().day,
        );

        List<DateTime> updatedCompletionDates = List<DateTime>.from(habit.completionDates);

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

        setState(() {
          _habits[habitIndex] = habit.copyWith(
            completedToday: isCompleting,
            progress: isCompleting ? 1.0 : 0.0,
            completionDates: updatedCompletionDates,
            streak: newStreak >= 0 ? newStreak : 0,
          );
        });

        await _habitRepository.saveHabits(_habits);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to update habit: ${e.toString()}';
      });
    }
  }

  Widget _buildErrorMessage() {
    if (_error == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SelectableText.rich(
        TextSpan(
          children: [
            const WidgetSpan(
              child: Icon(Icons.error_outline, color: Colors.red, size: 16),
            ),
            const TextSpan(text: ' '),
            TextSpan(
              text: _error,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteHabit(int habitId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Habit',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this habit?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete ?? false) {
      try {
        setState(() {
          _habits.removeWhere((habit) => habit.id == habitId);
        });
        await _habitRepository.saveHabits(_habits);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Habit deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete habit: $e')),
          );
        }
      }
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
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    // Cancel existing notification
                    await _notificationService.cancelReminder(habit.id);

                    final updatedHabit = habit.copyWith(
                      name: name,
                      category: category,
                      frequency: frequency,
                      reminderTime: reminderTime,
                      updatedAt: DateTime.now(),
                    );

                    // Schedule new notification if reminder is set
                    if (reminderTime != null) {
                      await _notificationService.scheduleHabitReminder(
                        id: updatedHabit.id,
                        habitName: updatedHabit.name,
                        scheduledTime: reminderTime,
                      );
                    }

                    setState(() {
                      final index = _habits.indexWhere(
                            (h) => h.id == habit.id,
                      );
                      if (index != -1) {
                        _habits[index] = updatedHabit;
                      }
                    });
                    await _habitRepository.saveHabits(_habits);
                    Navigator.pop(context);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Habit updated successfully')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to update habit: $e')),
                      );
                    }
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _HabitCard extends StatelessWidget {
  final Habit habit;
  final VoidCallback onToggleCompletion;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _HabitCard({
    required this.habit,
    required this.onToggleCompletion,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      habit.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: onEdit,
                      iconSize: 20,
                      color: colorScheme.primary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: onDelete,
                      iconSize: 20,
                      color: colorScheme.error,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        habit.name,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: habit.completedToday
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TweenAnimationBuilder(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(
                        begin: 0,
                        end: habit.completedToday ? 1 : 0,
                      ),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: 0.8 + (value * 0.2),
                          child: IconButton(
                            onPressed: onToggleCompletion,
                            icon: Icon(
                              Icons.check_circle,
                              color: Color.lerp(
                                colorScheme.onSurface.withOpacity(0.3),
                                Colors.green,
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
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      habit.frequency.substring(0, 1).toUpperCase() +
                          habit.frequency.substring(1),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_fire_department,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.streak} day streak',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                    if (habit.reminderTime != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('HH:mm').format(habit.reminderTime!),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: habit.progress,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}