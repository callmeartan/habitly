import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DailyInspiration extends StatelessWidget {
  const DailyInspiration({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final progressColor = isDark ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote,
                color: progressColor.withOpacity(0.7),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Daily Inspiration',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"The only way to do great work is to love what you do."',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: progressColor.withOpacity(0.9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '- Steve Jobs',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: progressColor.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


//unused widget for now maybe i use it later