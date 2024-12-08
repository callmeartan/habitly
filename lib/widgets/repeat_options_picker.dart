import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RepeatOptionsPicker extends StatefulWidget {
  final String? initialRepeatMode;
  final List<int>? initialRepeatDays;
  final int? initialRepeatInterval;
  final DateTime? initialRepeatUntil;
  final Function(String?) onRepeatModeChanged;
  final Function(List<int>?) onRepeatDaysChanged;
  final Function(int?) onRepeatIntervalChanged;
  final Function(DateTime?) onRepeatUntilChanged;

  const RepeatOptionsPicker({
    Key? key,
    this.initialRepeatMode,
    this.initialRepeatDays,
    this.initialRepeatInterval,
    this.initialRepeatUntil,
    required this.onRepeatModeChanged,
    required this.onRepeatDaysChanged,
    required this.onRepeatIntervalChanged,
    required this.onRepeatUntilChanged,
  }) : super(key: key);

  @override
  State<RepeatOptionsPicker> createState() => _RepeatOptionsPickerState();
}

class _RepeatOptionsPickerState extends State<RepeatOptionsPicker> {
  late String? _repeatMode;
  late List<int>? _repeatDays;
  late int? _repeatInterval;
  late DateTime? _repeatUntil;

  final List<String> _repeatModes = [
    'Never',
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  final List<String> _weekDays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  List<int> _getIntervalOptions(String? repeatMode) {
    switch (repeatMode) {
      case 'daily':
        return [1, 2, 3, 4, 5, 6, 7, 14, 30]; // Common daily intervals
      case 'weekly':
        return [1, 2, 3, 4]; // Up to monthly
      case 'monthly':
        return [1, 2, 3, 4, 6, 12]; // Up to yearly
      case 'yearly':
        return [1, 2, 3, 4, 5]; // Up to 5 years
      default:
        return [1];
    }
  }

  String _getIntervalLabel(int interval, String? repeatMode) {
    if (interval == 1) {
      return repeatMode == 'daily'
          ? 'day'
          : repeatMode == 'weekly'
              ? 'week'
              : repeatMode == 'monthly'
                  ? 'month'
                  : 'year';
    }
    return repeatMode == 'daily'
        ? 'days'
        : repeatMode == 'weekly'
            ? 'weeks'
            : repeatMode == 'monthly'
                ? 'months'
                : 'years';
  }

  @override
  void initState() {
    super.initState();
    _repeatMode = widget.initialRepeatMode;
    _repeatDays = widget.initialRepeatDays;
    _repeatInterval = widget.initialRepeatInterval ?? 1;
    _repeatUntil = widget.initialRepeatUntil;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _repeatMode,
              isExpanded: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.circular(12),
              hint: const Text('Never'),
              items: _repeatModes.map((String mode) {
                return DropdownMenuItem<String>(
                  value: mode.toLowerCase(),
                  child: Text(mode),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  _repeatMode = value == 'never' ? null : value;
                  if (_repeatMode != 'weekly') {
                    _repeatDays = null;
                  }
                });
                widget.onRepeatModeChanged(_repeatMode);
              },
            ),
          ),
        ),
        if (_repeatMode != null && _repeatMode != 'never') ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Repeat Every',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.2),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: ButtonTheme(
                          alignedDropdown: true,
                          child: DropdownButton<int>(
                            value: _repeatInterval,
                            isExpanded: true,
                            menuMaxHeight: 300,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            borderRadius: BorderRadius.circular(12),
                            items: _getIntervalOptions(_repeatMode)
                                .map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text(
                                  value.toString(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (int? value) {
                              setState(() => _repeatInterval = value);
                              widget.onRepeatIntervalChanged(value);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top: 29),
                  child: Text(
                    _getIntervalLabel(_repeatInterval ?? 1, _repeatMode),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        if (_repeatMode == 'weekly') ...[
          const SizedBox(height: 16),
          Text(
            'Repeat On',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(7, (index) {
              final dayNumber = index + 1;
              final isSelected =
                  _repeatDays?.contains(dayNumber) ?? false;
              return FilterChip(
                label: Text(_weekDays[index]),
                selected: isSelected,
                onSelected: (bool selected) {
                  setState(() {
                    _repeatDays ??= [];
                    if (selected) {
                      _repeatDays!.add(dayNumber);
                    } else {
                      _repeatDays!.remove(dayNumber);
                    }
                    _repeatDays!.sort();
                  });
                  widget.onRepeatDaysChanged(_repeatDays);
                },
              );
            }),
          ),
        ],
        if (_repeatMode != null && _repeatMode != 'never') ...[
          const SizedBox(height: 16),
          Text(
            'Ends',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _repeatUntil ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 3650)),
              );
              if (picked != null) {
                setState(() => _repeatUntil = picked);
                widget.onRepeatUntilChanged(picked);
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(_repeatUntil == null
                ? 'Never'
                : 'Until ${_repeatUntil!.toString().split(' ')[0]}'),
          ),
        ],
      ],
    );
  }
} 