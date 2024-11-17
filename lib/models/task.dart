import 'package:flutter/material.dart';

class Task {
  final int id;
  String title;
  String description;
  DateTime dueDate;
  TimeOfDay? dueTime;
  String priority;
  bool isCompleted;
  String category;
  DateTime? reminder;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.dueTime,
    required this.priority,
    this.isCompleted = false,
    required this.category,
    this.reminder,
  });

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    TimeOfDay? dueTime,
    String? priority,
    bool? isCompleted,
    String? category,
    DateTime? reminder,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      category: category ?? this.category,
      reminder: reminder ?? this.reminder,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'dueTime': dueTime != null ? '${dueTime!.hour}:${dueTime!.minute}' : null,
    'priority': priority,
    'isCompleted': isCompleted,
    'category': category,
    'reminder': reminder?.toIso8601String(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    TimeOfDay? parseDueTime() {
      if (json['dueTime'] == null) return null;
      final parts = json['dueTime'].split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      dueTime: parseDueTime(),
      priority: json['priority'],
      isCompleted: json['isCompleted'],
      category: json['category'],
      reminder: json['reminder'] != null ? DateTime.parse(json['reminder']) : null,
    );
  }
}