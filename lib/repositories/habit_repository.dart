import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import '../services/firebase_sync_service.dart';

class HabitRepository {
  static const String _key = 'habits';
  static const String _offlineDataKey = 'has_offline_habits_to_merge';
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
    try {
      final prefs = await SharedPreferences.getInstance();
      final isOfflineMode = prefs.getBool('offline_mode') ?? true;

      // If online and user is signed in, prioritize cloud data
      if (!isOfflineMode && _firebaseSyncService.isUserSignedIn) {
        final cloudHabits = await _firebaseSyncService.fetchHabitsFromCloud();
        // Save cloud data locally
        final habitsJson = cloudHabits.map((habit) => habit.toJson()).toList();
        await prefs.setString(_key, jsonEncode(habitsJson));
        return cloudHabits;
      }

      // Otherwise load local data
      final habitsString = prefs.getString(_key);
      if (habitsString == null) return [];

      final habitsList = jsonDecode(habitsString) as List;
      return habitsList
          .map((habitJson) => Habit.fromJson(habitJson))
          .where((habit) => !habit.isDeleted)
          .toList();
    } catch (e) {
      throw Exception('Failed to load habits: $e');
    }
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

  Future<bool> hasLocalData() async {
    try {
      final habits = await getAllHabits();
      return habits.isNotEmpty;
    } catch (e) {
      print('Error checking local habit data: $e');
      return false;
    }
  }

  Future<void> prepareForLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_offlineDataKey, true);
    } catch (e) {
      print('Error preparing habits for login: $e');
      throw Exception('Failed to prepare habits for login: $e');
    }
  }

  Future<void> clearLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
      await prefs.remove(_offlineDataKey);
    } catch (e) {
      print('Error clearing local habit data: $e');
      throw Exception('Failed to clear local habit data: $e');
    }
  }

  Future<List<Habit>> getAllHabits() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final habitsString = prefs.getString(_key);

      if (habitsString == null) return [];

      final habitsList = jsonDecode(habitsString) as List;
      return habitsList
          .map((habitJson) => Habit.fromJson(habitJson))
          .toList();
    } catch (e) {
      throw Exception('Failed to load habits: $e');
    }
  }
}