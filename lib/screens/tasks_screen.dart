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
    _tabController = TabController(length: 3, vsync: this);
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
      padding: const EdgeInsets.all(20),
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
                  'Edit Task',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: TaskForm(
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
                        if (formKey.currentState!.validate() && dueDate != null) {
                          try {
                            final updatedTask = task.copyWith(
                              title: title,
                              description: description,
                              category: category,
                              priority: priority,
                              dueDate: dueDate,
                              dueTime: dueTime,
                              reminder: reminder,
                            );

                            setState(() {
                              final index = _tasks.indexWhere((t) => t.id == task.id);
                              if (index != -1) {
                                _tasks[index] = updatedTask;
                              }
                            });

                            await _taskRepository.updateTask(updatedTask);

                            if (task.reminder != reminder) {
                              try {
                                // Cancel existing reminder if any
                                await _notificationService.cancelReminder(task.id);

                                // Schedule new reminder if set
                                if (reminder != null) {
                                  await _notificationService.scheduleTaskReminder(
                                    id: task.id,
                                    taskTitle: title,
                                    scheduledTime: reminder,
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to update reminder: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                          } catch (e) {
                            await _loadTasks();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
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
                  'Add New Task',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Flexible(
                  child: SingleChildScrollView(
                    child: TaskForm(
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
                        if (formKey.currentState!.validate() && dueDate != null) {
                          try {
                            final newTaskId = _tasks.isEmpty
                                ? 1
                                : _tasks.map((t) => t.id).reduce(max) + 1;

                            final newTask = Task(
                              id: newTaskId,
                              userId: _firebaseSyncService.currentUserId ?? '',
                              title: title,
                              description: description,
                              category: category,
                              priority: priority,
                              dueDate: dueDate!,
                              dueTime: dueTime,
                              reminder: reminder,
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            );

                            await _addTask(newTask);
                            await _loadTasks();

                            if (reminder != null) {
                              try {
                                await _notificationService.scheduleTaskReminder(
                                  id: newTask.id,
                                  taskTitle: newTask.title,
                                  scheduledTime: reminder,
                                );
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to set reminder: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                          } catch (e) {
                            // Handle error silently
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Add Task',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
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
    final today = DateTime.now();
    final upcomingTasks = _tasks.where((task) {
      final isToday = task.dueDate.year == today.year &&
                      task.dueDate.month == today.month &&
                      task.dueDate.day == today.day;
      return (task.dueDate.isAfter(today) || isToday) && !task.isCompleted;
    }).toList();
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
                        Theme.of(context).colorScheme.primary,
                      ),
                      strokeWidth: 3,
                    ),
                    Center(
                      child: Text(
                        '$completedTodayTasks/$totalTodayTasks',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
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
                  size: 32,
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