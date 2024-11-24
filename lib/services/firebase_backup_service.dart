import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';
import '../models/task.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Habits Collection Reference
  CollectionReference<Map<String, dynamic>> _habitsCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('habits');
  }

  // Tasks Collection Reference
  CollectionReference<Map<String, dynamic>> _tasksCollection(String userId) {
    return _firestore.collection('users').doc(userId).collection('tasks');
  }

  // Sync Habits to Cloud
  Future<void> syncHabitsToCloud(List<Habit> habits) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final habitsRef = _habitsCollection(currentUserId!);

    // First, delete all existing habits
    final existingHabits = await habitsRef.get();
    for (var doc in existingHabits.docs) {
      batch.delete(doc.reference);
    }

    // Then add all current habits
    for (var habit in habits) {
      final docRef = habitsRef.doc(habit.id.toString());
      batch.set(docRef, habit.toJson());
    }

    await batch.commit();
  }

  // Sync Tasks to Cloud
  Future<void> syncTasksToCloud(List<Task> tasks) async {
    if (currentUserId == null) return;

    final batch = _firestore.batch();
    final tasksRef = _tasksCollection(currentUserId!);

    // First, delete all existing tasks
    final existingTasks = await tasksRef.get();
    for (var doc in existingTasks.docs) {
      batch.delete(doc.reference);
    }

    // Then add all current tasks
    for (var task in tasks) {
      final docRef = tasksRef.doc(task.id.toString());
      batch.set(docRef, task.toJson());
    }

    await batch.commit();
  }

  // Fetch Habits from Cloud
  Future<List<Habit>> fetchHabitsFromCloud() async {
    if (currentUserId == null) return [];

    final snapshot = await _habitsCollection(currentUserId!).get();
    return snapshot.docs
        .map((doc) => Habit.fromJson(doc.data()))
        .where((habit) => !habit.isDeleted)
        .toList();
  }

  // Fetch Tasks from Cloud
  Future<List<Task>> fetchTasksFromCloud() async {
    if (currentUserId == null) return [];

    final snapshot = await _tasksCollection(currentUserId!).get();
    return snapshot.docs
        .map((doc) => Task.fromJson(doc.data()))
        .where((task) => !task.isDeleted)
        .toList();
  }

  // Listen to Habit Changes
  Stream<List<Habit>> listenToHabits() {
    if (currentUserId == null) return Stream.value([]);

    return _habitsCollection(currentUserId!).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Habit.fromJson(doc.data()))
          .where((habit) => !habit.isDeleted)
          .toList(),
    );
  }

  // Listen to Task Changes
  Stream<List<Task>> listenToTasks() {
    if (currentUserId == null) return Stream.value([]);

    return _tasksCollection(currentUserId!).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => Task.fromJson(doc.data()))
          .where((task) => !task.isDeleted)
          .toList(),
    );
  }

  // Check if user is signed in
  bool get isUserSignedIn => _auth.currentUser != null;

  // Get offline status
  Future<bool> get isOfflineMode async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_mode') ?? false;
  }
}