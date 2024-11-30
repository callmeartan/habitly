import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';
import '../widgets/task_form.dart';

class TaskCalendarScreen extends StatefulWidget {
  final List<Task> tasks;
  final Function(Task) onTaskAdded;

  const TaskCalendarScreen({
    Key? key,
    required this.tasks,
    required this.onTaskAdded,
  }) : super(key: key);

  @override
  _TaskCalendarScreenState createState() => _TaskCalendarScreenState();
}

class _TaskCalendarScreenState extends State<TaskCalendarScreen> {
  late CalendarFormat _calendarFormat;
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _calendarFormat = CalendarFormat.month;
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Task> _getTasksForDay(DateTime day) {
    return widget.tasks.where((task) {
      return isSameDay(task.dueDate, day);
    }).toList();
  }

  Future<void> _showAddTaskDialog(DateTime selectedDate) async {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    String category = 'Personal';
    String priority = 'Medium';
    DateTime? dueDate = selectedDate;
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
                        style: GoogleFonts.poppins(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          final newTask = Task(
                            id: DateTime.now().millisecondsSinceEpoch,
                            title: title,
                            description: description,
                            category: category,
                            priority: priority,
                            dueDate: dueDate ?? DateTime.now(),
                            dueTime: dueTime,
                            reminder: reminder,
                          );
                          widget.onTaskAdded(newTask);
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                      child: Text(
                        'Add Task',
                        style: GoogleFonts.poppins(color: Colors.white),
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

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.yellow;
      case 'low':
      default:
        return Colors.green;
    }
  }

  String _getHighestPriority(List<Task> tasks) {
    if (tasks.any((task) => task.priority.toLowerCase() == 'high')) {
      return 'high';
    } else if (tasks.any((task) => task.priority.toLowerCase() == 'medium')) {
      return 'medium';
    }
    return 'low';
  }

  int _getMonthlyTaskCount() {
    return widget.tasks.where((task) =>
    task.dueDate.year == _focusedDay.year &&
        task.dueDate.month == _focusedDay.month).length;
  }

  int _getHighPriorityTaskCount() {
    return widget.tasks.where((task) =>
    task.dueDate.year == _focusedDay.year &&
        task.dueDate.month == _focusedDay.month &&
        task.priority.toLowerCase() == 'high').length;
  }

  int _getUpcomingWeekTaskCount() {
    final weekFromNow = DateTime.now().add(const Duration(days: 7));
    return widget.tasks.where((task) =>
    task.dueDate.isAfter(DateTime.now()) &&
        task.dueDate.isBefore(weekFromNow)).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Task Calendar',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: theme.primaryTextTheme.titleLarge?.color,
              ),
            ),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.primaryTextTheme.titleLarge?.color?.withAlpha(204),
                ),
                const SizedBox(width: 4),
                Text(
                  'Task Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: theme.primaryTextTheme.titleLarge?.color?.withAlpha(204),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TableCalendar(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                    _showAddTaskDialog(selectedDay);
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
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, date, _) {
                      final tasks = _getTasksForDay(date);
                      final isSelected = isSameDay(date, _selectedDay);
                      final isToday = isSameDay(date, DateTime.now());

                      // Get highest priority for the day
                      String highestPriority = 'low';
                      if (tasks.isNotEmpty) {
                        highestPriority = _getHighestPriority(tasks);
                      }

                      // Determine background color
                      Color? backgroundColor;
                      if (isSelected) {
                        backgroundColor = colorScheme.primary;
                      } else if (tasks.isNotEmpty) {
                        backgroundColor = _getPriorityColor(highestPriority).withOpacity(0.2);
                      } else if (isToday) {
                        backgroundColor = colorScheme.primary.withOpacity(0.1);
                      }

                      return Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: GoogleFonts.poppins(
                              color: isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onSurface,
                              fontWeight: isSelected || isToday
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                    // Remove the markerBuilder since we're handling indicators 
                    // in the defaultBuilder
                    markerBuilder: null,
                  ),
                ),
              ),
            ),

            // Stats Container
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Task Overview',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Icon(
                        Icons.analytics_outlined,
                        color: colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        'Monthly Tasks',
                        _getMonthlyTaskCount().toString(),
                        Icons.calendar_month,
                        theme,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'High Priority',
                        _getHighPriorityTaskCount().toString(),
                        Icons.priority_high,
                        theme,
                        Colors.red,
                      ),
                      _buildStatCard(
                        'This Week',
                        _getUpcomingWeekTaskCount().toString(),
                        Icons.upcoming,
                        theme,
                        Colors.green,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(_selectedDay),
        backgroundColor: colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
      String label,
      String value,
      IconData icon,
      ThemeData theme,
      Color color,
      ) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
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
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }
}
