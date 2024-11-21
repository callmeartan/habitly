import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habitly/providers/theme_provider.dart';
import 'package:habitly/screens/login_intro_screen.dart';
import 'package:habitly/firebase_options.dart';
import 'package:habitly/screens/main_navigation_scaffold.dart';
import 'package:habitly/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize both Firebase and SharedPreferences
  final results = await Future.wait([
    Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    SharedPreferences.getInstance(),
  ]);

  final prefs = results[1] as SharedPreferences;

  // Check if this is a fresh install
  if (prefs.getInt('install_timestamp') == null) {
    prefs.clear(); // Clear any residual data
    prefs.setInt('install_timestamp', DateTime.now().millisecondsSinceEpoch);
    prefs.setBool('offline_mode', false);
  }

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
          home: const AuthenticationWrapper(),
        );
      },
    );
  }
}

class AuthenticationWrapper extends StatelessWidget {
  const AuthenticationWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        if (!prefsSnapshot.hasData) {
          return const SizedBox.shrink(); // Return empty widget while loading
        }

        final prefs = prefsSnapshot.data!;

        return StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, authSnapshot) {
            final isOfflineMode = prefs.getBool('offline_mode') ?? false;
            final lastLogoutTime = prefs.getInt('last_logout_timestamp');
            final installTime = prefs.getInt('install_timestamp');

            // If this is a fresh install or reinstall
            if (installTime == null) {
              prefs.setInt('install_timestamp', DateTime.now().millisecondsSinceEpoch);
              prefs.setBool('offline_mode', false);
              return const LoginScreen();
            }

            // Check if offline mode is valid
            bool isValidOfflineMode = false;
            if (isOfflineMode && lastLogoutTime != null) {
              final lastLogout = DateTime.fromMillisecondsSinceEpoch(lastLogoutTime);
              final now = DateTime.now();
              isValidOfflineMode = now.difference(lastLogout).inDays <= 30;
            }

            // Show main navigation if user is either authenticated or in valid offline mode
            if (authSnapshot.hasData || isValidOfflineMode) {
              return const MainNavigationScaffold();
            }

            // Default to login screen
            return const LoginScreen();
          },
        );
      },
    );
  }
}