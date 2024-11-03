// lib/models/habit.dart
class Habit {
  final int id;
  String name;
  String category;
  int streak;
  String frequency;
  bool completedToday;
  double progress;
  DateTime? reminderTime;
  List<DateTime> completionDates;  // Add this field

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.streak,
    required this.frequency,
    required this.completedToday,
    required this.progress,
    this.reminderTime,
    List<DateTime>? completionDates,  // Add this parameter
  }) : completionDates = completionDates ?? [];  // Initialize with empty list if null

  Habit copyWith({
    String? name,
    String? category,
    int? streak,
    String? frequency,
    bool? completedToday,
    double? progress,
    DateTime? reminderTime,
    List<DateTime>? completionDates,  // Add this
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      frequency: frequency ?? this.frequency,
      completedToday: completedToday ?? this.completedToday,
      progress: progress ?? this.progress,
      reminderTime: reminderTime ?? this.reminderTime,
      completionDates: completionDates ?? this.completionDates,  // Add this
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category,
    'streak': streak,
    'frequency': frequency,
    'completedToday': completedToday,
    'progress': progress,
    'reminderTime': reminderTime?.toIso8601String(),
    'completionDates': completionDates.map((date) => date.toIso8601String()).toList(),  // Add this
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    // Handle completion dates parsing
    List<DateTime> parsedDates = [];
    if (json['completionDates'] != null) {
      parsedDates = (json['completionDates'] as List)
          .map((dateStr) => DateTime.parse(dateStr as String))
          .toList();
    }

    return Habit(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      streak: json['streak'],
      frequency: json['frequency'],
      completedToday: json['completedToday'],
      progress: json['progress'].toDouble(),  // Ensure proper double conversion
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      completionDates: parsedDates,  // Add this
    );
  }

  // Optional: Add a method to normalize dates (remove time component)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Optional: Add helper methods for completion dates
  bool isCompletedOnDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    return completionDates.any((d) => _normalizeDate(d).isAtSameMomentAs(normalizedDate));
  }

  void addCompletionDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    if (!isCompletedOnDate(normalizedDate)) {
      completionDates.add(normalizedDate);
    }
  }

  void removeCompletionDate(DateTime date) {
    final normalizedDate = _normalizeDate(date);
    completionDates.removeWhere((d) => _normalizeDate(d).isAtSameMomentAs(normalizedDate));
  }

  // Optional: Add method to get current streak
  int getCurrentStreak() {
    if (completionDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completionDates)
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    DateTime currentDate = sortedDates[0];

    for (int i = 1; i < sortedDates.length; i++) {
      final difference = currentDate.difference(sortedDates[i]).inDays;
      if (difference == 1) {
        streak++;
        currentDate = sortedDates[i];
      } else {
        break;
      }
    }

    // Check if streak is still active (includes today or yesterday)
    final today = DateTime.now();
    final latestDate = sortedDates[0];
    final daysSinceLatest = today.difference(latestDate).inDays;

    if (daysSinceLatest > 1) {
      return 0; // Streak is broken if more than 1 day has passed
    }

    return streak;
  }

  // Optional: Add method to get best streak
  int getBestStreak() {
    if (completionDates.isEmpty) return 0;

    final sortedDates = List<DateTime>.from(completionDates)
      ..sort((a, b) => a.compareTo(b));

    int currentStreak = 1;
    int bestStreak = 1;
    DateTime currentDate = sortedDates[0];

    for (int i = 1; i < sortedDates.length; i++) {
      final difference = sortedDates[i].difference(currentDate).inDays;
      if (difference == 1) {
        currentStreak++;
        bestStreak = currentStreak > bestStreak ? currentStreak : bestStreak;
      } else {
        currentStreak = 1;
      }
      currentDate = sortedDates[i];
    }

    return bestStreak;
  }
}