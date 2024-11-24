class Habit {
  final int id;
  final String userId;
  String name;
  String category;
  int streak;
  String frequency;
  bool completedToday;
  double progress;
  DateTime? reminderTime;
  List<DateTime> completionDates;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;

  Habit({
    required this.id,
    String? userId,
    required this.name,
    required this.category,
    required this.streak,
    required this.frequency,
    required this.completedToday,
    required this.progress,
    this.reminderTime,
    List<DateTime>? completionDates,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
  }) :
        userId = userId ?? '',
        completionDates = completionDates ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Habit copyWith({
    String? name,
    String? category,
    int? streak,
    String? frequency,
    bool? completedToday,
    double? progress,
    DateTime? reminderTime,
    List<DateTime>? completionDates,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Habit(
      id: id,
      userId: userId,
      name: name ?? this.name,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      frequency: frequency ?? this.frequency,
      completedToday: completedToday ?? this.completedToday,
      progress: progress ?? this.progress,
      reminderTime: reminderTime ?? this.reminderTime,
      completionDates: completionDates ?? this.completionDates,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'name': name,
    'category': category,
    'streak': streak,
    'frequency': frequency,
    'completedToday': completedToday,
    'progress': progress,
    'reminderTime': reminderTime?.toIso8601String(),
    'completionDates': completionDates.map((date) => date.toIso8601String()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
  };

  factory Habit.fromJson(Map<String, dynamic> json) {
    List<DateTime> parsedDates = [];
    if (json['completionDates'] != null) {
      parsedDates = (json['completionDates'] as List)
          .map((dateStr) => DateTime.parse(dateStr as String))
          .toList();
    }

    return Habit(
      id: json['id'],
      userId: json['userId'] ?? '',
      name: json['name'],
      category: json['category'],
      streak: json['streak'],
      frequency: json['frequency'],
      completedToday: json['completedToday'],
      progress: json['progress'].toDouble(),
      reminderTime: json['reminderTime'] != null
          ? DateTime.parse(json['reminderTime'])
          : null,
      completionDates: parsedDates,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

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

    final today = DateTime.now();
    final latestDate = sortedDates[0];
    final daysSinceLatest = today.difference(latestDate).inDays;

    if (daysSinceLatest > 1) {
      return 0;
    }

    return streak;
  }

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