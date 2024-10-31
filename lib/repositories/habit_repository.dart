import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';

class HabitRepository {
  static const String _key = 'habits';

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = habits.map((habit) => {
      'id': habit.id,
      'name': habit.name,
      'category': habit.category,
      'streak': habit.streak,
      'frequency': habit.frequency,
      'completedToday': habit.completedToday,
      'progress': habit.progress,
    }).toList();
    await prefs.setString(_key, jsonEncode(habitsJson));
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsString = prefs.getString(_key);
    
    if (habitsString == null) return [];
    
    final habitsList = jsonDecode(habitsString) as List;
    return habitsList.map((habitJson) => Habit(
      id: habitJson['id'],
      name: habitJson['name'],
      category: habitJson['category'],
      streak: habitJson['streak'],
      frequency: habitJson['frequency'],
      completedToday: habitJson['completedToday'],
      progress: habitJson['progress'],
    )).toList();
  }

  Future<void> clearHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}