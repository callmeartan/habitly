import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/task.dart';
import '../services/firebase_sync_service.dart';
import 'package:collection/collection.dart';

class TaskRepository {
  static const String _key = 'tasks';
  static const String _offlineDataKey = 'has_offline_tasks_to_merge';
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();

  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_key, jsonEncode(tasksJson));

      await _firebaseSyncService.syncTasksToCloud(tasks);
    } catch (e) {
      throw Exception('Failed to save tasks: $e');
    }
  }

  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOfflineMode = prefs.getBool('offline_mode') ?? true;

      // If online and user is signed in, prioritize cloud data
      if (!isOfflineMode && _firebaseSyncService.isUserSignedIn) {
        final cloudTasks = await _firebaseSyncService.fetchTasksFromCloud();
        // Save cloud data locally
        final tasksJson = cloudTasks.map((task) => task.toJson()).toList();
        await prefs.setString(_key, jsonEncode(tasksJson));
        return cloudTasks;
      }

      // Otherwise load local data
      final tasksString = prefs.getString(_key);
      if (tasksString == null) return [];

      final tasksList = jsonDecode(tasksString) as List;
      return tasksList
          .map((taskJson) => Task.fromJson(taskJson))
          .where((task) => !task.isDeleted)
          .toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  Future<void> addTask(Task task) async {
    try {
      final tasks = await loadTasks();
      tasks.add(task);
      await saveTasks(tasks);
    } catch (e) {
      throw Exception('Failed to add task: $e');
    }
  }

  Future<void> updateTask(Task updatedTask) async {
    try {
      final tasks = await loadTasks();
      final index = tasks.indexWhere((task) => task.id == updatedTask.id);

      if (index != -1) {
        // If changing a recurring task, update future occurrences
        final oldTask = tasks[index];
        if (oldTask.repeatMode != null && 
            !_areRecurringSettingsEqual(oldTask, updatedTask)) {
          await _updateFutureOccurrences(oldTask, updatedTask, tasks);
        } else {
          tasks[index] = updatedTask;
        }
        
        await saveTasks(tasks);
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  bool _areRecurringSettingsEqual(Task task1, Task task2) {
    return task1.repeatMode == task2.repeatMode &&
        task1.repeatInterval == task2.repeatInterval &&
        task1.repeatUntil == task2.repeatUntil &&
        const ListEquality().equals(task1.repeatDays, task2.repeatDays);
  }

  Future<void> _updateFutureOccurrences(
    Task oldTask,
    Task updatedTask,
    List<Task> tasks,
  ) async {
    // Find all future occurrences of this recurring task
    final futureOccurrences = tasks.where((task) =>
        task.repeatMode == oldTask.repeatMode &&
        task.dueDate.isAfter(oldTask.dueDate) &&
        !task.isCompleted).toList();

    // Update or remove future occurrences based on new settings
    if (updatedTask.repeatMode == null) {
      // Remove future occurrences if recurring is disabled
      tasks.removeWhere((task) => futureOccurrences.contains(task));
    } else {
      // Update future occurrences with new settings
      for (final occurrence in futureOccurrences) {
        final index = tasks.indexWhere((t) => t.id == occurrence.id);
        if (index != -1) {
          tasks[index] = occurrence.copyWith(
            repeatMode: updatedTask.repeatMode,
            repeatInterval: updatedTask.repeatInterval,
            repeatDays: updatedTask.repeatDays,
            repeatUntil: updatedTask.repeatUntil,
          );
        }
      }
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      final tasks = await loadTasks();
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        // Instead of removing, mark as deleted
        tasks[taskIndex] = tasks[taskIndex].copyWith(
          isDeleted: true,
          updatedAt: DateTime.now(),
        );
        await saveTasks(tasks);
      }
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    try {
      final tasks = await loadTasks();
      final taskIndex = tasks.indexWhere((t) => t.id == taskId);

      if (taskIndex != -1) {
        final task = tasks[taskIndex];
        
        // If the task is recurring, create next instance
        if (task.repeatMode != null && !task.isCompleted) {
          await _handleRecurringTaskCompletion(task, tasks);
        } else {
          // For non-recurring tasks, simply toggle completion
          tasks[taskIndex] = task.copyWith(
            isCompleted: !task.isCompleted,
            updatedAt: DateTime.now(),
          );
        }

        await saveTasks(tasks);
      }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
  }

  Future<void> _handleRecurringTaskCompletion(Task task, List<Task> tasks) async {
    try {
      // 1. Mark current instance as completed
      final currentIndex = tasks.indexWhere((t) => t.id == task.id);
      final completedTask = task.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      );
      tasks[currentIndex] = completedTask;

      // 2. Calculate next occurrence
      final nextDueDate = _calculateNextOccurrence(task);
      
      // 3. Create next instance if within end date
      if (nextDueDate != null && 
          (task.repeatUntil == null || nextDueDate.isBefore(task.repeatUntil!))) {
        final newTask = Task(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: task.userId,
          title: task.title,
          description: task.description,
          dueDate: nextDueDate,
          dueTime: task.dueTime,
          priority: task.priority,
          category: task.category,
          isCompleted: false,
          reminder: task.reminder,
          repeatMode: task.repeatMode,
          repeatDays: task.repeatDays,
          repeatInterval: task.repeatInterval,
          repeatUntil: task.repeatUntil,
        );
        
        tasks.add(newTask);
      }

      // 4. Save both completed task and new instance
      await saveTasks(tasks);
      
      // 5. Sync with Firebase
      await _firebaseSyncService.syncTasksToCloud(tasks);
    } catch (e) {
      print('Failed to handle recurring task completion: $e');
      rethrow;
    }
  }

  DateTime? _calculateNextOccurrence(Task task) {
    if (task.repeatMode == null) return null;

    DateTime nextDate = task.dueDate;
    final now = DateTime.now();

    do {
      switch (task.repeatMode) {
        case 'daily':
          nextDate = nextDate.add(Duration(days: task.repeatInterval ?? 1));
          break;
          
        case 'weekly':
          if (task.repeatDays?.isNotEmpty ?? false) {
            // Find next day in repeatDays
            int currentWeekday = nextDate.weekday;
            List<int> sortedDays = [...task.repeatDays!]..sort();
            
            // Find next weekday in the list
            int? nextWeekday = sortedDays
                .firstWhere((day) => day > currentWeekday, 
                    orElse: () => sortedDays.first);
            
            if (nextWeekday <= currentWeekday) {
              // Move to next week if no remaining days this week
              nextDate = nextDate.add(
                Duration(days: 7 * (task.repeatInterval ?? 1) - 
                    currentWeekday + nextWeekday));
            } else {
              nextDate = nextDate.add(Duration(days: nextWeekday - currentWeekday));
            }
          } else {
            // Simple weekly repeat
            nextDate = nextDate.add(Duration(days: 7 * (task.repeatInterval ?? 1)));
          }
          break;
          
        case 'monthly':
          // Handle month overflow
          int year = nextDate.year;
          int month = nextDate.month + (task.repeatInterval ?? 1);
          while (month > 12) {
            month -= 12;
            year++;
          }
          
          // Handle invalid dates (e.g., March 31 -> April 30)
          int day = nextDate.day;
          while (true) {
            try {
              nextDate = DateTime(year, month, day);
              break;
            } catch (e) {
              day--;
              if (day <= 0) break;
            }
          }
          break;
          
        case 'yearly':
          nextDate = DateTime(
            nextDate.year + (task.repeatInterval ?? 1),
            nextDate.month,
            nextDate.day,
          );
          break;
          
        default:
          return null;
      }
    } while (nextDate.isBefore(now));

    // If task has a due time, preserve it
    if (task.dueTime != null) {
      nextDate = DateTime(
        nextDate.year,
        nextDate.month,
        nextDate.day,
        task.dueTime!.hour,
        task.dueTime!.minute,
      );
    }

    return nextDate;
  }

  Future<List<Task>> getTasksByCategory(String category) async {
    try {
      final tasks = await loadTasks();
      return tasks.where((task) => task.category == category).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by category: $e');
    }
  }

  Future<List<Task>> getTasksByDate(DateTime date) async {
    try {
      final tasks = await loadTasks();
      return tasks.where((task) {
        final taskDate = DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
        );
        final compareDate = DateTime(
          date.year,
          date.month,
          date.day,
        );
        return taskDate.isAtSameMomentAs(compareDate);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get tasks by date: $e');
    }
  }

  Future<List<Task>> getOverdueTasks() async {
    try {
      final tasks = await loadTasks();
      final now = DateTime.now();
      return tasks.where((task) {
        if (task.isCompleted) return false;

        final taskDateTime = task.dueTime != null
            ? DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
          task.dueTime!.hour,
          task.dueTime!.minute,
        )
            : DateTime(
          task.dueDate.year,
          task.dueDate.month,
          task.dueDate.day,
          23,
          59,
          59,
        );

        return taskDateTime.isBefore(now);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get overdue tasks: $e');
    }
  }

  Future<List<Task>> getUpcomingTasks({int days = 7}) async {
    try {
      final tasks = await loadTasks();
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));

      return tasks.where((task) {
        if (task.isCompleted) return false;

        return task.dueDate.isAfter(now) &&
            task.dueDate.isBefore(futureDate);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get upcoming tasks: $e');
    }
  }

  Future<void> clearCompletedTasks() async {
    try {
      final tasks = await loadTasks();
      tasks.removeWhere((task) => task.isCompleted);
      await saveTasks(tasks);
    } catch (e) {
      throw Exception('Failed to clear completed tasks: $e');
    }
  }

  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      throw Exception('Failed to clear tasks: $e');
    }
  }

  Future<void> syncWithCloud() async {
    try {
      final cloudTasks = await _firebaseSyncService.fetchTasksFromCloud();
      await saveTasks(cloudTasks);
    } catch (e) {
      print('Failed to sync tasks from cloud: $e');
      rethrow;
    }
  }

  Future<bool> hasLocalData() async {
    try {
      final tasks = await getAllTasks();
      return tasks.isNotEmpty;
    } catch (e) {
      print('Error checking local task data: $e');
      return false;
    }
  }

  Future<void> prepareForLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineDataKey, true);
    } catch (e) {
      print('Error preparing tasks for login: $e');
      throw Exception('Failed to prepare tasks for login: $e');
    }
  }

  Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_offlineDataKey);
    } catch (e) {
      print('Error clearing local task data: $e');
      throw Exception('Failed to clear local task data: $e');
    }
  }

  Future<List<Task>> getAllTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_key);

      if (tasksString == null) return [];

      final tasksList = jsonDecode(tasksString) as List;
      return tasksList
          .map((taskJson) => Task.fromJson(taskJson))
          .toList(); // Note: This returns all tasks, including deleted ones
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }
}