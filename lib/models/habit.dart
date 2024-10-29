import 'package:flutter/foundation.dart';

class Habit {
  final int id;
  String name;
  String category;
  int streak;
  String frequency;
  bool completedToday;
  double progress;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.streak,
    required this.frequency,
    required this.completedToday,
    required this.progress,
  });

  Habit copyWith({
    String? name,
    String? category,
    int? streak,
    String? frequency,
    bool? completedToday,
    double? progress,
  }) {
    return Habit(
      id: id,
      name: name ?? this.name,
      category: category ?? this.category,
      streak: streak ?? this.streak,
      frequency: frequency ?? this.frequency,
      completedToday: completedToday ?? this.completedToday,
      progress: progress ?? this.progress,
    );
  }
}