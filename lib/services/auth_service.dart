import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  Future<bool> isSignedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isOfflineMode = prefs.getBool('offline_mode') ?? false;
    final lastLogoutTime = prefs.getInt('last_logout_timestamp');

    // Check if offline mode is valid (not expired)
    if (isOfflineMode && lastLogoutTime != null) {
      final lastLogout = DateTime.fromMillisecondsSinceEpoch(lastLogoutTime);
      final now = DateTime.now();
      // Consider offline mode valid if last logout was within 30 days
      if (now.difference(lastLogout).inDays <= 30) {
        return true;
      } else {
        // Clear expired offline mode
        await prefs.setBool('offline_mode', false);
        return false;
      }
    }

    return _auth.currentUser != null;
  }

  // Sign in with Apple
  Future<UserCredential> signInWithApple() async {
    try {
      // Request credential for Apple Sign In
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Create OAuthCredential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // If this is first sign in and we got the name, save it
      if (appleCredential.givenName != null || appleCredential.familyName != null) {
        await _saveUserInfo(
          userCredential.user!,
          appleCredential.givenName,
          appleCredential.familyName,
        );

        // Also save to SharedPreferences as backup
        final prefs = await SharedPreferences.getInstance();
        if (appleCredential.givenName != null) {
          await prefs.setString('user_given_name', appleCredential.givenName!);
        }
        if (appleCredential.familyName != null) {
          await prefs.setString('user_family_name', appleCredential.familyName!);
        }
      }

      // Reset offline mode and update login timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', false);
      await prefs.setInt('last_login_timestamp', DateTime.now().millisecondsSinceEpoch);

      return userCredential;
    } catch (e) {
      print("Error in Apple Sign In: $e");
      rethrow;
    }
  }

  Future<void> _saveUserInfo(User user, String? firstName, String? lastName) async {
    if (firstName != null || lastName != null) {
      String displayName = '';
      if (firstName != null) displayName += firstName;
      if (lastName != null) displayName += ' $lastName';
      displayName = displayName.trim();

      if (displayName.isNotEmpty) {
        try {
          await user.updateDisplayName(displayName);
          // Force a reload to ensure we have the latest user data
          await user.reload();
        } catch (e) {
          print("Error updating user profile: $e");
        }
      }
    }
  }

  // Enable offline mode
  Future<void> enableOfflineMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', true);
    await prefs.setInt('last_login_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Always sign out from Firebase if possible
      if (_auth.currentUser != null) {
        await _auth.signOut();
      }

      // Save the logout timestamp
      await prefs.setInt('last_logout_timestamp', DateTime.now().millisecondsSinceEpoch);

      // Clear all preferences except essential ones
      final themeMode = prefs.getBool('theme_mode');
      final installTimestamp = prefs.getInt('install_timestamp');
      await prefs.clear();

      // Restore only necessary values
      if (themeMode != null) {
        await prefs.setBool('theme_mode', themeMode);
      }
      if (installTimestamp != null) {
        await prefs.setInt('install_timestamp', installTimestamp);
      }

      // Explicitly set offline mode to false
      await prefs.setBool('offline_mode', false);
    } catch (e) {
      print("Error signing out: $e");
      rethrow;
    }
  }

  // Delete account
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.delete();
      }
      await signOut(); // This will also clear preferences

      // Clear install timestamp to force fresh start
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('install_timestamp');
    } catch (e) {
      print("Error deleting account: $e");
      rethrow;
    }
  }
}