import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'interactive_time_picker.dart';

class TaskForm extends StatefulWidget {
  final String initialTitle;
  final String initialDescription;
  final String initialCategory;
  final String initialPriority;
  final DateTime? initialDueDate;
  final TimeOfDay? initialDueTime;
  final DateTime? initialReminder;
  final Function(String) onTitleChanged;
  final Function(String) onDescriptionChanged;
  final Function(String?) onCategoryChanged;
  final Function(String?) onPriorityChanged;
  final Function(DateTime?) onDueDateChanged;
  final Function(TimeOfDay?) onDueTimeChanged;
  final Function(DateTime?) onReminderChanged;
  final GlobalKey<FormState> formKey;

  const TaskForm({
    Key? key,
    this.initialTitle = '',
    this.initialDescription = '',
    this.initialCategory = 'Personal',
    this.initialPriority = 'Medium',
    this.initialDueDate,
    this.initialDueTime,
    this.initialReminder,
    required this.onTitleChanged,
    required this.onDescriptionChanged,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onDueDateChanged,
    required this.onDueTimeChanged,
    required this.onReminderChanged,
    required this.formKey,
  }) : super(key: key);

  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  late String currentCategory;
  late String currentPriority;
  late DateTime? currentDueDate;
  late TimeOfDay? currentDueTime;
  late DateTime? currentReminder;

  @override
  void initState() {
    super.initState();
    currentCategory = widget.initialCategory;
    currentPriority = widget.initialPriority;
    currentDueDate = widget.initialDueDate;
    currentDueTime = widget.initialDueTime;
    currentReminder = widget.initialReminder;
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
            _buildTitleInput(colorScheme),
            const SizedBox(height: 24),
            _buildDescriptionInput(colorScheme),
            const SizedBox(height: 32),
            _buildCategoryChips(colorScheme),
            const SizedBox(height: 32),
            _buildPrioritySelector(colorScheme),
            const SizedBox(height: 32),
            _buildDateTimeSection(colorScheme),
            const SizedBox(height: 32),
            _buildReminderPicker(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleInput(ColorScheme colorScheme) {
    return TextFormField(
      initialValue: widget.initialTitle,
      style: GoogleFonts.poppins(
        fontSize: 28,
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: 'Task title...',
        hintStyle: GoogleFonts.poppins(
          color: colorScheme.onSurface.withOpacity(0.5),
          fontSize: 28,
          fontWeight: FontWeight.w300,
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      validator: (value) {
        if (value?.trim().isEmpty ?? true) {
          return 'Please enter a task title';
        }
        return null;
      },
      onChanged: widget.onTitleChanged,
    );
  }

  Widget _buildDescriptionInput(ColorScheme colorScheme) {
    return TextFormField(
      initialValue: widget.initialDescription,
      style: GoogleFonts.poppins(
        fontSize: 16,
        height: 1.5,
        color: colorScheme.onSurface,
      ),
      maxLines: 3,
      decoration: InputDecoration(
        hintText: 'Add description...',
        hintStyle: GoogleFonts.poppins(
          color: colorScheme.onSurface.withOpacity(0.5),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary),
        ),
      ),
      onChanged: widget.onDescriptionChanged,
    );
  }

  Widget _buildCategoryChips(ColorScheme colorScheme) {
    final categories = [
      ('Personal', Icons.person_outline),
      ('Work', Icons.work_outline),
      ('School', Icons.school_outlined),
      ('Shopping', Icons.shopping_bag_outlined),
      ('Health', Icons.favorite_outline),
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
          spacing: 16,
          runSpacing: 16,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
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

  Widget _buildPrioritySelector(ColorScheme colorScheme) {
    final priorities = [
      ('Low', Colors.green),
      ('Medium', Colors.orange),
      ('High', Colors.red),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
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
            children: priorities.map((priority) {
              final isSelected = currentPriority == priority.$1;
              return Expanded(
                child: InkWell(
                  onTap: () {
                    setState(() => currentPriority = priority.$1);
                    widget.onPriorityChanged(priority.$1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? priority.$2.withOpacity(0.2) : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: priority.$2,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priority.$1,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: isSelected ? priority.$2 : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
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

  Widget _buildDateTimeSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Due Date & Time',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.6),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _showDatePicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: currentDueDate != null
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentDueDate != null
                            ? DateFormat('MMM d').format(currentDueDate!)
                            : 'Set date',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: currentDueDate != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: () => _showTimePicker(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 20,
                        color: currentDueTime != null
                            ? colorScheme.primary
                            : colorScheme.onSurface.withOpacity(0.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currentDueTime != null
                            ? _formatTimeOfDay(currentDueTime!)
                            : 'Set time',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: currentDueTime != null
                              ? colorScheme.onSurface
                              : colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
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
          onTap: () => _showReminderPicker(context),
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
                  Icons.notifications_outlined,
                  size: 20,
                  color: currentReminder != null
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    currentReminder != null
                        ? DateFormat('MMM d, y • h:mm a').format(currentReminder!)
                        : 'Add reminder',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: currentReminder != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
                if (currentReminder != null)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    onPressed: () {
                      setState(() => currentReminder = null);
                      widget.onReminderChanged(null);
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => currentDueDate = picked);
      widget.onDueDateChanged(picked);
    }
  }

  Future<void> _showTimePicker(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: currentDueTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => currentDueTime = picked);
      widget.onDueTimeChanged(picked);
    }
  }

  void _showReminderPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => InteractiveTimePicker(
        initialTime: currentReminder,
        onTimeSelected: (DateTime? time) {
          setState(() => currentReminder = time);
          widget.onReminderChanged(time);
        },
      ),
    );
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }
}