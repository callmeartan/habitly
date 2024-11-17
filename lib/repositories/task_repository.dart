import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '/models/task.dart';
class TaskRepository {
  static const String _key = 'tasks';


  Future<void> saveTasks(List<Task> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_key, jsonEncode(tasksJson));
    } catch (e) {
      throw Exception('Failed to save tasks: $e');
    }
  }

  Future<List<Task>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_key);

      if (tasksString == null) return [];

      final tasksList = jsonDecode(tasksString) as List;
      return tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
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
        tasks[index] = updatedTask;
        await saveTasks(tasks);
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  Future<void> deleteTask(int taskId) async {
    try {
      final tasks = await loadTasks();
      tasks.removeWhere((task) => task.id == taskId);
      await saveTasks(tasks);
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }

  Future<void> toggleTaskCompletion(int taskId) async {
    try {
      final tasks = await loadTasks();
      final index = tasks.indexWhere((task) => task.id == taskId);

      if (index != -1) {
        tasks[index] = tasks[index].copyWith(
          isCompleted: !tasks[index].isCompleted,
        );
        await saveTasks(tasks);
      } else {
        throw Exception('Task not found');
      }
    } catch (e) {
      throw Exception('Failed to toggle task completion: $e');
    }
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
}