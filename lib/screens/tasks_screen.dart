import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../repositories/task_repository.dart';
import '../widgets/task_form.dart';
import '../widgets/task_card.dart'; // Import the new TaskCard widget
import 'dart:math' show max;

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

  Widget _buildTaskList(List<Task> tasks, ColorScheme colorScheme) {
    if (tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_outlined,
              size: 64,
              color: colorScheme.onBackground.withOpacity(0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks yet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                color: colorScheme.onBackground.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
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

      await _taskRepository.updateTask(updatedTask);
      await _loadTasks();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedTask.isCompleted ? 'Task completed! 🎉' : 'Task marked as incomplete',
            style: GoogleFonts.poppins(),
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update task: $e'),
          backgroundColor: Colors.red,
        ),
      );
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

                            await _taskRepository.updateTask(updatedTask);
                            await _loadTasks();

                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Task updated successfully'),
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update task: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
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
                              title: title,
                              description: description,
                              category: category,
                              priority: priority,
                              dueDate: dueDate!,
                              dueTime: dueTime,
                              reminder: reminder,
                            );

                            await _taskRepository.addTask(newTask);
                            await _loadTasks();

                            if (!mounted) return;
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Task added successfully')),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add task: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } else if (dueDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please set a due date')),
                          );
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
      try {
        await _taskRepository.deleteTask(taskId);
        await _loadTasks();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete task: $e')),
        );
      }
    }
  }

  Widget _buildAllTasksList(ColorScheme colorScheme) {
    return _buildTaskList(_tasks, colorScheme);
  }

  Widget _buildTodayTasksList(ColorScheme colorScheme) {
    final todayTasks = _tasks.where((task) {
      final today = DateTime.now();
      return task.dueDate.year == today.year &&
          task.dueDate.month == today.month &&
          task.dueDate.day == today.day;
    }).toList();
    return _buildTaskList(todayTasks, colorScheme);
  }

  Widget _buildUpcomingTasksList(ColorScheme colorScheme) {
    final today = DateTime.now();
    final upcomingTasks = _tasks.where((task) => task.dueDate.isAfter(today)).toList();
    return _buildTaskList(upcomingTasks, colorScheme);
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

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(colorScheme),
            _buildTabBar(colorScheme),
            _buildSearchBar(colorScheme),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTasksList(colorScheme),
                  _buildTodayTasksList(colorScheme),
                  _buildUpcomingTasksList(colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: colorScheme.primary,
        icon: const Icon(Icons.add),
        label: Text(
          'New Task',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    final completedTasks = _tasks.where((task) => task.isCompleted).length;
    final totalTasks = _tasks.length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tasks',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '$completedTasks/$totalTasks',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                Text(
                  'Completed',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: TabBar(
        controller: _tabController,
        labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.primaryContainer.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Today'),
          Tab(text: 'Upcoming'),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search tasks...',
          hintStyle: GoogleFonts.poppins(
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          filled: true,
          fillColor: colorScheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary),
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