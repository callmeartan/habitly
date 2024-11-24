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
      reminder: reminder ?? this.reminder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isDeleted: isDeleted ?? this.isDeleted,
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
    );
  }
}