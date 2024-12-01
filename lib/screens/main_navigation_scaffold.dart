import 'package:flutter/material.dart';
import 'package:habitly/screens/habit_dashboard.dart';
import 'package:habitly/screens/habits_screen.dart';
import 'package:habitly/screens/tasks_screen.dart';
import 'package:habitly/screens/profile_screen.dart';

import '../widgets/custom_bottom_nav_bar.dart';
import '../providers/navigation_state.dart';

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({Key? key}) : super(key: key);

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;
  final _dashboardKey = GlobalKey<HabitDashboardState>();

  @override
  void initState() {
    super.initState();
    _screens = [
      HabitDashboard(key: _dashboardKey),
      HabitsScreen(
        onHabitUpdated: _refreshDashboard,
      ),
      TasksScreen(
        onTaskUpdated: _refreshDashboard,
      ),
      const ProfileScreen(),
    ];
  }

  void _refreshDashboard() {
    _dashboardKey.currentState?.refreshDashboard();
  }

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return NavigationState(
      onNavigate: _onItemSelected,
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: CustomBottomNavBar(
          selectedIndex: _selectedIndex,
          onItemSelected: _onItemSelected,
        ),
      ),
    );
  }
}
