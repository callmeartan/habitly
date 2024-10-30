import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import '../widgets/habit_card.dart';
import '../widgets/habit_form.dart';

class HabitDashboard extends StatefulWidget {
  const HabitDashboard({Key? key}) : super(key: key);

  @override
  _HabitDashboardState createState() => _HabitDashboardState();
}

class _HabitDashboardState extends State<HabitDashboard> {
  List<Habit> habits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Simulate loading time
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        habits = [
          Habit(
            id: 1,
            name: 'Morning Meditation',
            category: 'Health',
            streak: 5,
            frequency: 'daily',
            completedToday: false,
            progress: 0.85,
          ),
          Habit(
            id: 2,
            name: 'Read 30 Minutes',
            category: 'Personal Development',
            streak: 12,
            frequency: 'daily',
            completedToday: true,
            progress: 0.92,
          ),
          Habit(
            id: 3,
            name: 'Weekly Exercise',
            category: 'Health',
            streak: 3,
            frequency: 'weekly',
            completedToday: false,
            progress: 0.75,
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load habits: $e';
        _isLoading = false;
      });
    }
  }

  void toggleHabitCompletion(int habitId) {
    setState(() {
      final habitIndex = habits.indexWhere((h) => h.id == habitId);
      if (habitIndex != -1) {
        final habit = habits[habitIndex];
        habits[habitIndex] = habit.copyWith(
          completedToday: !habit.completedToday,
        );
      }
    });
  }

  void _deleteHabit(int habitId) async {
    try {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Habit'),
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
              onPressed: () {
                setState(() {
                  habits.removeWhere((habit) => habit.id == habitId);
                });
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
            onNameChanged: (value) => name = value,
            onCategoryChanged: (value) => category = value ?? category,
            onFrequencyChanged: (value) => frequency = value ?? frequency,
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  setState(() {
                    final habitIndex = habits.indexWhere((h) => h.id == habit.id);
                    if (habitIndex != -1) {
                      habits[habitIndex] = habit.copyWith(
                        name: name,
                        category: category,
                        frequency: frequency,
                      );
                    }
                  });
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
            onNameChanged: (value) => name = value,
            onCategoryChanged: (value) => category = value ?? category,
            onFrequencyChanged: (value) => frequency = value ?? frequency,
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
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newHabit = Habit(
                    id: habits.length + 1,
                    name: name,
                    category: category,
                    streak: 0,
                    frequency: frequency,
                    completedToday: false,
                    progress: 0.0,
                  );
                  setState(() {
                    habits.add(newHabit);
                  });
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Habitly',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey[800],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
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

              // Stats Cards
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

              // Active Habits Section
              Text(
                'Active Habits',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),

              // Habits List
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