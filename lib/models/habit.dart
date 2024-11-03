class Habit {
  final int id;
  String name;
  String category;
  int streak;
  String frequency;
  bool completedToday;
  double progress;
  DateTime? reminderTime;
  List<DateTime> completionDates; // Add this line

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.streak,
    required this.frequency,
    required this.completedToday,
    required this.progress,
    this.reminderTime,
    List<DateTime>? completionDates, // Add this parameter
  }) : completionDates = completionDates ?? []; // Initialize empty list if null

  Habit copyWith({
    String? name,
    String? category,
    int? streak,
    String? frequency,
    bool? completedToday,
    double? progress,
    DateTime? reminderTime,
    List<DateTime>? completionDates, // Add this
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
      completionDates: completionDates ?? this.completionDates, // Add this
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
    'completionDates': completionDates.map((date) => date.toIso8601String()).toList(), // Add this
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    streak: json['streak'],
    frequency: json['frequency'],
    completedToday: json['completedToday'],
    progress: json['progress'],
    reminderTime: json['reminderTime'] != null
        ? DateTime.parse(json['reminderTime'])
        : null,
    completionDates: (json['completionDates'] as List<dynamic>?)
        ?.map((dateStr) => DateTime.parse(dateStr))
        .toList() ?? [], // Add this
  );
}