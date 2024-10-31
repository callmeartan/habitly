// lib/widgets/habit_form.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitForm extends StatelessWidget {
  final String initialName;
  final String initialCategory;
  final String initialFrequency;
  final DateTime? initialReminderTime;
  final Function(String) onNameChanged;
  final Function(String?) onCategoryChanged;
  final Function(String?) onFrequencyChanged;
  final Function(DateTime?) onReminderTimeChanged;
  final GlobalKey<FormState> formKey;

  const HabitForm({
    Key? key,
    required this.initialName,
    required this.initialCategory,
    required this.initialFrequency,
    this.initialReminderTime,
    required this.onNameChanged,
    required this.onCategoryChanged,
    required this.onFrequencyChanged,
    required this.onReminderTimeChanged,
    required this.formKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = ['Health', 'Personal Development', 'Work', 'Family', 'Other'];
    final frequencies = ['daily', 'weekly', 'monthly'];

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: initialName,
              decoration: const InputDecoration(
                labelText: 'Habit Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a habit name';
                }
                return null;
              },
              onChanged: onNameChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              value: initialCategory,
              items: categories.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onCategoryChanged,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Frequency',
                border: OutlineInputBorder(),
              ),
              value: initialFrequency,
              items: frequencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: onFrequencyChanged,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(
                'Set Reminder',
                style: GoogleFonts.poppins(),
              ),
              subtitle: Text(
                initialReminderTime != null
                    ? 'Reminder set for ${_formatTime(initialReminderTime!)}'
                    : 'No reminder set',
                style: GoogleFonts.poppins(),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (initialReminderTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => onReminderTimeChanged(null),
                    ),
                  const Icon(Icons.access_time),
                ],
              ),
              onTap: () async {
                final TimeOfDay? selectedTime = await showTimePicker(
                  context: context,
                  initialTime: initialReminderTime != null
                      ? TimeOfDay.fromDateTime(initialReminderTime!)
                      : TimeOfDay.now(),
                );

                if (selectedTime != null) {
                  final now = DateTime.now();
                  final reminderTime = DateTime(
                    now.year,
                    now.month,
                    now.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  onReminderTimeChanged(reminderTime);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}