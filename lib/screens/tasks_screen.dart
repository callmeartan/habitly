import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../widgets/task_form.dart';
import '../widgets/task_card.dart';
import 'dart:math' show max;
import '../services/firebase_sync_service.dart';
import '../services/notification_service.dart';

class TasksScreen extends StatefulWidget {
  final VoidCallback onTaskUpdated;

  const TasksScreen({
    Key? key,
    required this.onTaskUpdated,
  }) : super(key: key);

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TaskRepository _taskRepository = TaskRepository();
  List<Task> _tasks = [];
  bool _isLoading = true;
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  String _searchQuery = '';
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskRepository.loadTasks();
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load tasks: $e')),
        );
      }
    }
  }

  Widget _buildTaskList(List<Task> tasks, Color progressColor) {
    final filteredTasks = tasks.where((task) {
      if (_searchQuery.isEmpty) return true;
      return task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          task.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.task_outlined : Icons.search_off,
              size: 64,
              color: progressColor.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No tasks yet' : 'No matching tasks found',
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return TaskCard(
          task: task,
          onToggleComplete: () => _toggleTaskCompletion(task),
          onEdit: () => _editTask(task),
          onDelete: () => _deleteTask(task.id),
        );
      },
    );
  }

  Future<void> _toggleTaskCompletion(Task task) async {
    try {
      final updatedTask = task.copyWith(
        isCompleted: !task.isCompleted,
      );

      setState(() {
        final index = _tasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _tasks[index] = updatedTask;
        }
      });

      await _taskRepository.updateTask(updatedTask);
    } catch (e) {
      await _loadTasks();
    }
  }

  Future<void> _editTask(Task task) async {
    final formKey = GlobalKey<FormState>();
    String title = task.title;
    String description = task.description;
    String category = task.category;
    String priority = task.priority;
    DateTime? dueDate = task.dueDate;
    TimeOfDay? dueTime = task.dueTime;
    DateTime? reminder = task.reminder;
    String? repeatMode = task.repeatMode;
    List<int>? repeatDays = task.repeatDays;
    int? repeatInterval = task.repeatInterval;
    DateTime? repeatUntil = task.repeatUntil;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TaskForm(
                    initialTitle: title,
                    initialDescription: description,
                    initialCategory: category,
                    initialPriority: priority,
                    initialDueDate: dueDate,
                    initialDueTime: dueTime,
                    initialReminder: reminder,
                    initialRepeatMode: repeatMode,
                    initialRepeatDays: repeatDays,
                    initialRepeatInterval: repeatInterval,
                    initialRepeatUntil: repeatUntil,
                    formKey: formKey,
                    onTitleChanged: (value) => title = value,
                    onDescriptionChanged: (value) => description = value,
                    onCategoryChanged: (value) => category = value ?? category,
                    onPriorityChanged: (value) => priority = value ?? priority,
                    onDueDateChanged: (value) => dueDate = value,
                    onDueTimeChanged: (value) => dueTime = value,
                    onReminderChanged: (value) {
                      reminder = value;
                      if (value == null) {
                        _notificationService.cancelReminder(task.id);
                      }
                    },
                    onRepeatModeChanged: (value) => repeatMode = value,
                    onRepeatDaysChanged: (value) => repeatDays = value,
                    onRepeatIntervalChanged: (value) => repeatInterval = value,
                    onRepeatUntilChanged: (value) => repeatUntil = value,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            try {
                              await _notificationService.cancelReminder(task.id);

                              final updatedTask = task.copyWith(
                                title: title,
                                description: description,
                                category: category,
                                priority: priority,
                                dueDate: dueDate,
                                dueTime: dueTime,
                                reminder: reminder,
                                repeatMode: repeatMode,
                                repeatDays: repeatMode == null ? null : repeatDays,
                                repeatInterval: repeatMode == null ? null : repeatInterval,
                                repeatUntil: repeatMode == null ? null : repeatUntil,
                                updatedAt: DateTime.now(),
                              );

                              await _taskRepository.updateTask(updatedTask);
                              await _loadTasks();

                              if (mounted) {
                                Navigator.pop(context);
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update task: $e')),
                                );
                              }
                            }
                          }
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
    DateTime? dueDate = DateTime.now();
    TimeOfDay? dueTime;
    DateTime? reminder;
    String? repeatMode;
    List<int>? repeatDays;
    int? repeatInterval;
    DateTime? repeatUntil;

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Task',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 20),
                  TaskForm(
                    initialTitle: title,
                    initialDescription: description,
                    initialCategory: category,
                    initialPriority: priority,
                    initialDueDate: dueDate,
                    initialDueTime: dueTime,
                    initialReminder: reminder,
                    initialRepeatMode: repeatMode,
                    initialRepeatDays: repeatDays,
                    initialRepeatInterval: repeatInterval,
                    initialRepeatUntil: repeatUntil,
                    formKey: formKey,
                    onTitleChanged: (value) => title = value,
                    onDescriptionChanged: (value) => description = value,
                    onCategoryChanged: (value) => category = value ?? category,
                    onPriorityChanged: (value) => priority = value ?? priority,
                    onDueDateChanged: (value) => dueDate = value,
                    onDueTimeChanged: (value) => dueTime = value,
                    onReminderChanged: (value) => reminder = value,
                    onRepeatModeChanged: (value) => repeatMode = value,
                    onRepeatDaysChanged: (value) => repeatDays = value,
                    onRepeatIntervalChanged: (value) => repeatInterval = value,
                    onRepeatUntilChanged: (value) => repeatUntil = value,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            // Generate a notification-safe ID
                            final taskId = DateTime.now().millisecondsSinceEpoch % 100000000;
                            
                            final task = Task(
                              id: taskId,  // Use the safe ID
                              userId: '',  // Or get from auth
                              title: title,
                              description: description,
                              dueDate: dueDate ?? DateTime.now(),
                              dueTime: dueTime,
                              priority: priority,
                              category: category,
                              reminder: reminder,
                              repeatMode: repeatMode,
                              repeatDays: repeatDays,
                              repeatInterval: repeatInterval,
                              repeatUntil: repeatUntil,
                            );

                            if (reminder != null) {
                              await _notificationService.scheduleTaskReminder(
                                id: taskId,  // Use the safe ID
                                taskTitle: title,
                                scheduledTime: reminder,
                              );
                            }

                            await _taskRepository.addTask(task);
                            await _loadTasks();
                            widget.onTaskUpdated();
                            if (mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        child: const Text('Add Task'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _addTask(Task newTask) async {
    try {
      setState(() {
        _tasks.add(newTask);
      });

      await _taskRepository.addTask(newTask);
    } catch (e) {
      setState(() {
        _tasks.removeWhere((t) => t.id == newTask.id);
      });
      rethrow;
    }
  }

  Future<void> _deleteTask(int taskId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Task',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this task?',
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
      final taskToDelete = _tasks.firstWhere((t) => t.id == taskId);

      try {
        setState(() {
          _tasks.removeWhere((t) => t.id == taskId);
        });
        await _taskRepository.deleteTask(taskId);
      } catch (e) {
        setState(() {
          _tasks.add(taskToDelete);
        });
      }
    }
  }

  Widget _buildAllTasksList(Color progressColor) {
    return _buildTaskList(_tasks, progressColor);
  }

  Widget _buildTodayTasksList(Color progressColor) {
    final todayTasks = _tasks.where((task) {
      final today = DateTime.now();
      return task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day &&
          !task.isCompleted;
    }).toList();
    return _buildTaskList(todayTasks, progressColor);
  }

  Widget _buildUpcomingTasksList(Color progressColor) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final upcomingTasks = _tasks.where((task) {
      final taskDate = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      return !task.isCompleted;  // Show all incomplete tasks
    }).toList();
    
    // Sort tasks by due date
    upcomingTasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    
    return _buildTaskList(upcomingTasks, progressColor);
  }

  Widget _buildCompletedTasksList(Color progressColor) {
    final completedTasks = _tasks.where((task) => task.isCompleted).toList();
    return _buildTaskList(completedTasks, progressColor);
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
            _buildTabBar(theme, progressColor),
            _buildSearchBar(theme, progressColor),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildUpcomingTasksList(progressColor),
                  _buildTodayTasksList(progressColor),
                  _buildCompletedTasksList(progressColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color progressColor) {
    final today = DateTime.now();
    final todayTasks = _tasks.where((task) {
      return task.dueDate.year == today.year &&
             task.dueDate.month == today.month &&
             task.dueDate.day == today.day;
    }).toList();
    
    final completedTodayTasks = todayTasks.where((task) => task.isCompleted).length;
    final totalTodayTasks = todayTasks.length;
    final completionRate = totalTodayTasks > 0 ? completedTodayTasks / totalTodayTasks : 0.0;

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
                  'Tasks',
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
                        '$completedTodayTasks/$totalTodayTasks',
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
                onPressed: _showAddTaskDialog,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: progressColor,
                  size: 42,
                ),
                tooltip: 'Add Task',
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
          Tab(text: 'Upcoming'),
          Tab(text: 'Today'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, Color progressColor) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        style: GoogleFonts.poppins(
          color: progressColor,
        ),
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: GoogleFonts.poppins(
            color: progressColor.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: progressColor.withOpacity(0.5),
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(
              Icons.clear,
              color: progressColor.withOpacity(0.5),
            ),
            onPressed: () => setState(() => _searchQuery = ''),
          )
              : null,
          filled: true,
          fillColor: progressColor.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: progressColor.withOpacity(0.1),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}