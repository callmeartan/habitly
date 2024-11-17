import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitly/screens/habit_dashboard.dart';
import 'package:habitly/providers/theme_provider.dart';
import 'package:habitly/screens/login_intro_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habitly/firebase_options.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'package:habitly/screens/main_navigation_scaffold.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize both Firebase and SharedPreferences
  await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    SharedPreferences.getInstance(),
  ]).then((results) {
    final prefs = results[1] as SharedPreferences;
    runApp(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(prefs),
        child: const MyApp(),
      ),
    );
  });
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
          home: const MainNavigationScaffold(),
        );
      },
    );
  }
}