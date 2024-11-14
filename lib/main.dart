import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitly/screens/habit_dashboard.dart';
import 'package:habitly/providers/theme_provider.dart';
import 'package:habitly/screens/login_intro_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(prefs),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Habitly',
          theme: themeProvider.theme,
          home: const LoginScreen(),        );
      },
    );
  }
}