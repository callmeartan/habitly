import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/firebase_sync_service.dart';

class HabitRepository {
  static const String _key = 'habits';
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();

  Future<void> saveHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    final habitsJson = habits.map((habit) => habit.toJson()).toList();
    await prefs.setString(_key, jsonEncode(habitsJson));

    try {
      await _firebaseSyncService.syncHabitsToCloud(habits);
    } catch (e) {
      print('Failed to sync habits to cloud: $e');
    }
  }

  Future<List<Habit>> loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final habitsString = prefs.getString(_key);

    if (habitsString == null) return [];

    final habitsList = jsonDecode(habitsString) as List;
    return habitsList
        .map((habitJson) => Habit.fromJson(habitJson))
        .where((habit) => !habit.isDeleted)
        .toList();
  }

  Future<void> clearHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> syncWithCloud() async {
    try {
      final cloudHabits = await _firebaseSyncService.fetchHabitsFromCloud();
      await saveHabits(cloudHabits);
    } catch (e) {
      print('Failed to sync habits from cloud: $e');
      rethrow;
    }
  }

  Future<void> deleteHabit(int habitId) async {
    final habits = await loadHabits();
    final habitIndex = habits.indexWhere((h) => h.id == habitId);

    if (habitIndex != -1) {
      // Instead of removing, mark as deleted
      habits[habitIndex] = habits[habitIndex].copyWith(
        isDeleted: true,
        updatedAt: DateTime.now(),
      );
      await saveHabits(habits);
    }
  }
}