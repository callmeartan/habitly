class Habit {
  final int id;
  final String name;
  final String category;
  final int streak;
  final String frequency;
  bool completedToday;
  final double progress;

  Habit({
    required this.id,
    required this.name,
    required this.category,
    required this.streak,
    required this.frequency,
    required this.completedToday,
    required this.progress,
  });
}