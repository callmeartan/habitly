import 'package:flutter/material.dart';
import 'package:habitly/screens/habit_dashboard.dart';
import 'package:habitly/screens/habit_calendar_screen.dart';
import 'package:habitly/screens/tasks_screen.dart';
import 'package:habitly/screens/habits_screen.dart';



import '../widgets/custom_bottom_nav_bar.dart';


class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({Key? key}) : super(key: key);

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _selectedIndex = 0;

  // Keep track of navigation history for better state preservation
  final List<Widget> _screens = [
    const HabitDashboard(),
    const HabitsScreen(),
    const TasksScreen(),
    const Placeholder(), // Replace with ProfileScreen
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemSelected: _onItemSelected,
      ),
    );
  }
}