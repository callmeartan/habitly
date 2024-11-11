import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/habit.dart';
import 'habit_card.dart';
import 'empty_habits.dart';

class HabitsList extends StatelessWidget {
  final List<Habit> habits;
  final Function(Habit) onEdit;
  final Function(int) onDelete;
  final Function(int) onToggleCompletion;

  const HabitsList({
    Key? key,
    required this.habits,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleCompletion,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Habits',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: habits.isEmpty
              ? const EmptyHabits()
              : ListView.builder(
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: HabitCard(
                  habit: habit,
                  onEdit: () => onEdit(habit),
                  onDelete: () => onDelete(habit.id),
                  onToggleCompletion: () => onToggleCompletion(habit.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
