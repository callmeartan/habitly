import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'interactive_time_picker.dart';

class HabitForm extends StatefulWidget {
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
  State<HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<HabitForm> {
  late String currentCategory;
  late String currentFrequency;
  late DateTime? currentReminderTime;

  @override
  void initState() {
    super.initState();
    currentCategory = widget.initialCategory;
    currentFrequency = widget.initialFrequency;
    currentReminderTime = widget.initialReminderTime;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Form(
      key: widget.formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildNameInput(colorScheme),
            const SizedBox(height: 24),
            _buildCategorySection(colorScheme),
            const SizedBox(height: 24),
            _buildFrequencySection(colorScheme),
            const SizedBox(height: 24),
            _buildReminderSection(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInput(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What habit do you want to build?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: widget.initialName,
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: 'e.g., Morning Meditation',
            hintStyle: GoogleFonts.poppins(
                color: colorScheme.onSurface.withOpacity(0.5)),
            filled: true,
            fillColor: colorScheme.surface,
            prefixIcon: Icon(Icons.edit_outlined,
                color: colorScheme.onSurface.withOpacity(0.5)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
          validator: (value) {
            if (value?.trim().isEmpty ?? true) {
              return 'Please enter a habit name';
            }
            return null;
          },
          onChanged: widget.onNameChanged,
        ),
      ],
    );
  }

  Widget _buildCategorySection(ColorScheme colorScheme) {
    final categories = [
      'Health',
      'Personal Development',
      'Work',
      'Family',
      'Other',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: categories.map((category) {
              final isSelected = currentCategory == category;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      currentCategory = category;
                    });
                    widget.onCategoryChanged(category);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: category != categories.last
                              ? colorScheme.outline
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getCategoryIcon(category),
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withOpacity(0.7),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            category,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFrequencySection(ColorScheme colorScheme) {
    final frequencies = {
      'daily': 'Every day',
      'weekly': 'Every week',
      'monthly': 'Every month',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How often?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline),
          ),
          child: Column(
            children: frequencies.entries.map((entry) {
              final isSelected = currentFrequency == entry.key;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      currentFrequency = entry.key;
                    });
                    widget.onFrequencyChanged(entry.key);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: entry.key != frequencies.keys.last
                              ? colorScheme.outline
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : colorScheme.onSurface.withOpacity(0.5),
                              width: 2,
                            ),
                            color: isSelected
                                ? colorScheme.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? Icon(
                            Icons.check,
                            size: 12,
                            color: colorScheme.onPrimary,
                          )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          entry.value,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                            fontWeight: isSelected
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Reminder',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _showTimePickerSheet,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.outline),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentReminderTime != null
                              ? 'Reminder set for'
                              : 'Set a reminder',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (currentReminderTime != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(currentReminderTime!),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: colorScheme.onSurface.withOpacity(0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (currentReminderTime != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  currentReminderTime = null;
                });
                widget.onReminderTimeChanged(null);
              },
              icon: Icon(
                Icons.remove_circle_outline,
                color: colorScheme.error,
                size: 20,
              ),
              label: Text(
                'Remove Reminder',
                style: GoogleFonts.poppins(
                  color: colorScheme.error,
                  fontSize: 14,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showTimePickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InteractiveTimePicker(
        initialTime: currentReminderTime,
        onTimeSelected: (DateTime? time) {
          setState(() {
            currentReminderTime = time;
          });
          widget.onReminderTimeChanged(time);
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Health':
        return Icons.favorite_outline;
      case 'Personal Development':
        return Icons.psychology_outlined;
      case 'Work':
        return Icons.work_outline;
      case 'Family':
        return Icons.people_outline;
      default:
        return Icons.category_outlined;
    }
  }
}