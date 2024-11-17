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
            const SizedBox(height: 32),
            _buildCategoryChips(colorScheme),
            const SizedBox(height: 32),
            _buildFrequencyToggle(colorScheme),
            const SizedBox(height: 32),
            _buildReminderPicker(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildNameInput(ColorScheme colorScheme) {
    return TextFormField(
      initialValue: widget.initialName,
      style: GoogleFonts.poppins(
        fontSize: 24,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: 'Name your habit...',
        hintStyle: GoogleFonts.poppins(
          color: colorScheme.onSurface.withOpacity(0.5),
          fontSize: 24,
          fontWeight: FontWeight.w300,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return 'Please enter a habit name';
        }
        return null;
      },
      onChanged: widget.onNameChanged,
    );
  }

  Widget _buildCategoryChips(ColorScheme colorScheme) {
    final categories = [
      ('Health', Icons.favorite_outline),
      ('Personal', Icons.psychology_outlined),
      ('Work', Icons.work_outline),
      ('Family', Icons.people_outline),
      ('Other', Icons.category_outlined),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            final isSelected = currentCategory == category.$1;
            return InkWell(
              onTap: () {
                setState(() => currentCategory = category.$1);
                widget.onCategoryChanged(category.$1);
              },
              borderRadius: BorderRadius.circular(24),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.$2,
                      size: 18,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurface.withOpacity(0.8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.$1,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFrequencyToggle(ColorScheme colorScheme) {
    final frequencies = ['daily', 'weekly', 'monthly'];
    final labels = ['Daily', 'Weekly', 'Monthly'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Frequency',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            children: List.generate(frequencies.length, (index) {
              final isSelected = currentFrequency == frequencies[index];
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => currentFrequency = frequencies[index]);
                    widget.onFrequencyChanged(frequencies[index]);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primary : null,
                      borderRadius: BorderRadius.horizontal(
                        left: index == 0 ? const Radius.circular(12) : Radius.zero,
                        right: index == frequencies.length - 1
                            ? const Radius.circular(12)
                            : Radius.zero,
                      ),
                    ),
                    child: Text(
                      labels[index],
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildReminderPicker(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reminder',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _showTimePickerSheet,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: currentReminderTime != null
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentReminderTime != null
                        ? _formatTime(currentReminderTime!)
                        : 'Add reminder',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: currentReminderTime != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                if (currentReminderTime != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    onPressed: () {
                      setState(() => currentReminderTime = null);
                      widget.onReminderTimeChanged(null);
                    },
                  ),
              ],
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
          setState(() => currentReminderTime = time);
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
}