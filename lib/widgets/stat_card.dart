import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final double? progress;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Enhanced color palette for better contrast
    final cardColor = isDark
        ? const Color(0xFF2C2C2E) // Dark mode secondary background
        : Colors.white; // Pure white for light mode

    final accentColor = isDark
        ? const Color(0xFF0A84FF) // iOS dark mode blue
        : const Color(0xFF007AFF); // iOS light mode blue

    return Container(
      width: 170,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (!isDark) BoxShadow(
            color: Colors.black.withOpacity(0.08), // Slightly stronger shadow
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          if (!isDark) BoxShadow(
            color: Colors.black.withOpacity(0.03), // Subtle inner shadow
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: !isDark ? Border.all(
          color: Colors.black.withOpacity(0.05), // Subtle border
          width: 1,
        ) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Title and icon row
          Row(
            children: [
              Icon(
                icon,
                color: accentColor,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Value display
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          // Progress bar
          if (progress != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress! / 100,
                    backgroundColor: accentColor.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}