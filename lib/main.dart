import 'package:flutter/material.dart';
import 'package:habitly/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:habitly/providers/theme_provider.dart';
import 'package:habitly/screens/login_intro_screen.dart';
import 'package:habitly/firebase_options.dart';
import 'package:habitly/screens/main_navigation_scaffold.dart';
import 'package:habitly/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:habitly/repositories/task_repository.dart';
import 'package:habitly/repositories/habit_repository.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
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

  Future<void> _loadUserData(String userId) async {
    final taskRepo = TaskRepository();
    final habitRepo = HabitRepository();

    // Clear any existing local data first
    await taskRepo.clearLocalData();
    await habitRepo.clearLocalData();

    // Load cloud data
    await Future.wait([
      taskRepo.syncWithCloud(),
      habitRepo.syncWithCloud(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, prefsSnapshot) {
        if (!prefsSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final prefs = prefsSnapshot.data!;

        return StreamBuilder<User?>(
          stream: AuthService().authStateChanges,
          builder: (context, authSnapshot) {
            // Handle initial loading state
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final isOfflineMode = prefs.getBool('offline_mode') ?? false;
            final lastLogoutTime = prefs.getInt('last_logout_timestamp');
            final installTime = prefs.getInt('install_timestamp');

            // Fresh install handling
            if (installTime == null) {
              prefs.setInt('install_timestamp', DateTime.now().millisecondsSinceEpoch);
              prefs.setBool('offline_mode', false);
              return const LoginScreen();
            }

            // Check if user just logged in
            if (authSnapshot.hasData && !isOfflineMode) {
              // Load user data from cloud
              _loadUserData(authSnapshot.data!.uid);
            }

            // Validate offline mode
            bool isValidOfflineMode = false;
            if (isOfflineMode && lastLogoutTime != null) {
              final lastLogout = DateTime.fromMillisecondsSinceEpoch(lastLogoutTime);
              isValidOfflineMode = DateTime.now().difference(lastLogout).inDays <= 30;
            }

            if (authSnapshot.hasData || isValidOfflineMode) {
              return const MainNavigationScaffold();
            }

            return const LoginScreen();
          },
        );
      },
    );
  }
}