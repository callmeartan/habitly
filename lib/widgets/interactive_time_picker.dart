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
  bool _showHours = true;

  @override
  void initState() {
    super.initState();
    final now = widget.initialTime ?? DateTime.now();
    _selectedHour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    _selectedMinute = now.minute;
    _isAM = now.hour < 12;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
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
            _buildClock(colorScheme),
            _buildActionButtons(colorScheme),
          ],
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
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTimeUnit(_selectedHour.toString().padLeft(2, '0'), _showHours, () {
            setState(() => _showHours = true);
          }, colorScheme),
          Text(
            ':',
            style: GoogleFonts.poppins(
              fontSize: 48,
              fontWeight: FontWeight.w300,
              color: colorScheme.onSurface,
            ),
          ),
          _buildTimeUnit(_selectedMinute.toString().padLeft(2, '0'), !_showHours, () {
            setState(() => _showHours = false);
          }, colorScheme),
          const SizedBox(width: 20),
          _buildAmPmSelector(colorScheme),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, bool isSelected, VoidCallback onTap, ColorScheme colorScheme) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 48,
            fontWeight: FontWeight.w300,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
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

  Widget _buildClock(ColorScheme colorScheme) {
    return Container(
      width: 280,
      height: 280,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Clock face
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.onSurface.withOpacity(0.2),
                width: 2,
              ),
            ),
          ),
          // Numbers
          ..._buildClockNumbers(colorScheme),
          // Clock hands
          if (_showHours)
            _buildHourHand(colorScheme)
          else
            _buildMinuteHand(colorScheme),
          // Center dot
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          // Minute dot (only show when in minute mode)
          if (!_showHours)
            _buildMinuteDot(colorScheme),
        ],
      ),
    );
  }

  List<Widget> _buildClockNumbers(ColorScheme colorScheme) {
    List<Widget> numbers = [];
    final radius = 120.0;

    for (int i = 1; i <= 12; i++) {
      final angle = (i * 30 - 90) * (pi / 180);
      final x = cos(angle) * radius;
      final y = sin(angle) * radius;

      numbers.add(
        Positioned(
          left: 140 + x - 20,
          top: 140 + y - 20,
          child: _buildClockNumber(i, colorScheme),
        ),
      );
    }

    return numbers;
  }

  Widget _buildClockNumber(int number, ColorScheme colorScheme) {
    final isSelected = _showHours
        ? number == _selectedHour
        : number * 5 == _selectedMinute;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_showHours) {
            _selectedHour = number;
          } else {
            _selectedMinute = number * 5;
          }
        });
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? colorScheme.primary : Colors.transparent,
        ),
        child: Center(
          child: Text(
            number.toString(),
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHourHand(ColorScheme colorScheme) {
    final angle = (_selectedHour * 30 - 90) * (pi / 180);
    return _buildHand(angle, 80, colorScheme);
  }

  Widget _buildMinuteHand(ColorScheme colorScheme) {
    final angle = (_selectedMinute * 6 - 90) * (pi / 180);
    return _buildHand(angle, 100, colorScheme);
  }

  Widget _buildHand(double angle, double length, ColorScheme colorScheme) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        height: 2,
        width: length,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(1),
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildMinuteDot(ColorScheme colorScheme) {
    final angle = (_selectedMinute * 6 - 90) * (pi / 180);
    final radius = 100.0;
    final x = cos(angle) * radius;
    final y = sin(angle) * radius;

    return Positioned(
      left: 140 + x - 6,
      top: 140 + y - 6,
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
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