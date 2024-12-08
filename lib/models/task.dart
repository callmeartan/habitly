import 'package:flutter/material.dart';

class Task {
  final int id;
  final String userId;
  String title;
  String description;
  DateTime dueDate;
  TimeOfDay? dueTime;
  String priority;
  bool isCompleted;
  String category;
  DateTime? reminder;
  DateTime createdAt;
  DateTime updatedAt;
  bool isDeleted;
  String? repeatMode;
  List<int>? repeatDays;
  int? repeatInterval;
  DateTime? repeatUntil;

  Task({
    required this.id,
    String? userId,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.dueTime,
    required this.priority,
    this.isCompleted = false,
    required this.category,
    this.reminder,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isDeleted = false,
    this.repeatMode,
    this.repeatDays,
    this.repeatInterval = 1,
    this.repeatUntil,
  }) :
        userId = userId ?? '',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    String? priority,
    bool? isCompleted,
    String? category,
    DateTime? reminder,
    DateTime? updatedAt,
    bool? isDeleted,
    String? repeatMode,
    List<int>? repeatDays,
    int? repeatInterval,
    DateTime? repeatUntil,
  }) {
    return Task(
      id: id,
      userId: userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      reminder: reminder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
      repeatMode: repeatMode ?? this.repeatMode,
      repeatDays: repeatDays ?? this.repeatDays,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      repeatUntil: repeatUntil ?? this.repeatUntil,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'dueTime': dueTime != null
        ? '${dueTime!.hour}:${dueTime!.minute}'
        : null,
    'priority': priority,
    'isCompleted': isCompleted,
    'category': category,
    'reminder': reminder?.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'isDeleted': isDeleted,
    'repeatMode': repeatMode,
    'repeatDays': repeatDays,
    'repeatInterval': repeatInterval,
    'repeatUntil': repeatUntil?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parsedDueTime;
    if (json['dueTime'] != null) {
      final timeParts = (json['dueTime'] as String).split(':');
      parsedDueTime = TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      );
    }

    return Task(
      id: json['id'],
      userId: json['userId'] ?? '',
      title: json['title'],
      description: json['description'] ?? '',
      dueDate: DateTime.parse(json['dueDate']),
      dueTime: parsedDueTime,
      priority: json['priority'],
      isCompleted: json['isCompleted'],
      category: json['category'],
      reminder: json['reminder'] != null
          ? DateTime.parse(json['reminder'])
          : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      isDeleted: json['isDeleted'] ?? false,
      repeatMode: json['repeatMode'],
      repeatDays: json['repeatDays'] != null 
          ? List<int>.from(json['repeatDays'])
          : null,
      repeatInterval: json['repeatInterval'],
      repeatUntil: json['repeatUntil'] != null
          ? DateTime.parse(json['repeatUntil'])
          : null,
    );
  }

  DateTime getNextOccurrence() {
    if (repeatMode == null) return dueDate;

    DateTime nextDate = dueDate;
    final now = DateTime.now();

    while (nextDate.isBefore(now)) {
      switch (repeatMode) {
        case 'daily':
          nextDate = nextDate.add(Duration(days: repeatInterval ?? 1));
          break;
        case 'weekly':
          if (repeatDays != null && repeatDays!.isNotEmpty) {
            DateTime temp = nextDate.add(const Duration(days: 1));
            while (!repeatDays!.contains(temp.weekday)) {
              temp = temp.add(const Duration(days: 1));
            }
            nextDate = temp;
          } else {
            nextDate = nextDate.add(Duration(days: 7 * (repeatInterval ?? 1)));
          }
          break;
        case 'monthly':
          nextDate = DateTime(
            nextDate.year,
            nextDate.month + (repeatInterval ?? 1),
            nextDate.day,
          );
          break;
        case 'yearly':
          nextDate = DateTime(
            nextDate.year + (repeatInterval ?? 1),
            nextDate.month,
            nextDate.day,
          );
          break;
        default:
          return dueDate;
      }

      if (repeatUntil != null && nextDate.isAfter(repeatUntil!)) {
        return dueDate;
      }
    }

    return nextDate;
  }
}