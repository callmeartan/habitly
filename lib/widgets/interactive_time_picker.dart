import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InteractiveTimePicker extends StatefulWidget {
  final DateTime? initialTime;
  final Function(DateTime?) onTimeSelected;

  const InteractiveTimePicker({
    Key? key,
    this.initialTime,
    required this.onTimeSelected,
  }) : super(key: key);

  @override
  State<InteractiveTimePicker> createState() => _InteractiveTimePickerState();
}

class _InteractiveTimePickerState extends State<InteractiveTimePicker> {
  late int _selectedHour;
  late int _selectedMinute;
  late bool _isAM;
  late TextEditingController _hourController;
  late TextEditingController _minuteController;
  late FocusNode _hourFocus;
  late FocusNode _minuteFocus;

  @override
  void initState() {
    super.initState();
    final now = widget.initialTime ?? DateTime.now();
    _selectedHour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    _selectedMinute = now.minute;
    _isAM = now.hour < 12;
    
    _hourController = TextEditingController(text: _selectedHour.toString().padLeft(2, '0'));
    _minuteController = TextEditingController(text: _selectedMinute.toString().padLeft(2, '0'));
    _hourFocus = FocusNode();
    _minuteFocus = FocusNode();
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _hourFocus.dispose();
    _minuteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(colorScheme),
                _buildTimeDisplay(colorScheme),
                _buildActionButtons(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Set Reminder Time',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeTextField(
            controller: _hourController,
            focusNode: _hourFocus,
            nextFocus: _minuteFocus,
            onChanged: (value) {
              if (value.isNotEmpty) {
                final hour = int.parse(value);
                if (hour >= 1 && hour <= 12) {
                  _selectedHour = hour;
                } else {
                  _hourController.text = _selectedHour.toString().padLeft(2, '0');
                }
                if (value.length == 2) _minuteFocus.requestFocus();
              }
            },
            colorScheme: colorScheme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: GoogleFonts.poppins(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          _buildTimeTextField(
            controller: _minuteController,
            focusNode: _minuteFocus,
            onChanged: (value) {
              if (value.isNotEmpty) {
                final minute = int.parse(value);
                if (minute >= 0 && minute <= 59) {
                  _selectedMinute = minute;
                } else {
                  _minuteController.text = _selectedMinute.toString().padLeft(2, '0');
                }
              }
            },
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 12),
          _buildAmPmSelector(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTimeTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocus,
    required Function(String) onChanged,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        decoration: InputDecoration(
          counterText: '',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        style: GoogleFonts.poppins(
          fontSize: 48,
          fontWeight: FontWeight.w300,
          color: colorScheme.onSurface,
        ),
        onChanged: (value) {
          if (value.length > 2) {
            controller.text = value.substring(0, 2);
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
          onChanged(value);
        },
      ),
    );
  }

  Widget _buildAmPmSelector(ColorScheme colorScheme) {
    return Column(
      children: [
        _buildAmPmButton('AM', colorScheme),
        const SizedBox(height: 8),
        _buildAmPmButton('PM', colorScheme),
      ],
    );
  }

  Widget _buildAmPmButton(String text, ColorScheme colorScheme) {
    final isSelected = (text == 'AM' && _isAM) || (text == 'PM' && !_isAM);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _isAM = text == 'AM'),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: isSelected ? colorScheme.primary : Colors.transparent,
          ),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () {
                widget.onTimeSelected(null);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: colorScheme.outline),
                ),
              ),
              child: Text(
                'Remove',
                style: GoogleFonts.poppins(
                  color: colorScheme.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: FilledButton(
              onPressed: () {
                final hour = _isAM ? _selectedHour : _selectedHour + 12;
                final time = DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  hour == 24 ? 0 : hour,
                  _selectedMinute,
                );
                widget.onTimeSelected(time);
                Navigator.pop(context);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Set Time',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}