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
          home: FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, prefsSnapshot) {
              if (!prefsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return StreamBuilder<User?>(
                stream: AuthService().authStateChanges,
                builder: (context, authSnapshot) {
                  final isOfflineMode = prefsSnapshot.data!.getBool('offline_mode') ?? false;

                  // User is either in offline mode or authenticated
                  if (isOfflineMode || authSnapshot.hasData) {
                    return const MainNavigationScaffold();
                  }

                  // User is neither in offline mode nor authenticated
                  return const LoginScreen();
                },
              );
            },
          ),
        );
      },
    );
  }
}