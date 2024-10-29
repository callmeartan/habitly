import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HabitForm extends StatelessWidget {
  final String initialName;
  final String initialCategory;
  final String initialFrequency;
  final Function(String) onNameChanged;
  final Function(String?) onCategoryChanged;
  final Function(String?) onFrequencyChanged;
  final GlobalKey<FormState> formKey;

  const HabitForm({
    Key? key,
    required this.initialName,
    required this.initialCategory,
    required this.initialFrequency,
    required this.onNameChanged,
    required this.onCategoryChanged,
    required this.onFrequencyChanged,
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
          ],
        ),
      ),
    );
  }
}
