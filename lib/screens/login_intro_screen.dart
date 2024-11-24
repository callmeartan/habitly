import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:habitly/screens/main_navigation_scaffold.dart';
import 'package:habitly/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 1),
              // Hero Section
              Text(
                'Habitly',
                style: GoogleFonts.poppins(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Get it done. Build the habit.',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Join thousands of people who use Habitly to transform their lives, one habit at a time.",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[400],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              // Login Options
              _buildLoginButton(
                onTap: () => _handleAppleLogin(context),
                text: 'Continue with Apple',
                icon: Icons.apple,
                context: context,
              ),
              const SizedBox(height: 16),
              _buildLoginButton(
                onTap: () => _handleGoogleLogin(context),
                text: 'Continue with Google',
                icon: Icons.g_mobiledata,
                context: context,
              ),
              const SizedBox(height: 16),
              _buildOfflineButton(
                onTap: () => _handleOfflineMode(context),
                context: context,
              ),
              const SizedBox(height: 32),
              // Privacy Note
              Center(
                child: Text(
                  'By continuing, you agree to our Terms and Privacy Policy',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton({
    required VoidCallback onTap,
    required String text,
    required IconData icon,
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            Colors.white.withOpacity(0.95),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.black,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineButton({
    required VoidCallback onTap,
    required BuildContext context,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              'Continue Offline',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[400],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAppleLogin(BuildContext context) async {
    try {
      // Clear offline mode preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', false);

      final authService = AuthService();
      final result = await authService.signInWithApple();

      print("Successfully signed in with Apple. User: ${result.user?.email}");

      if (!context.mounted) return;

      // Navigate to main screen immediately after successful sign in
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScaffold()),
            (route) => false,
      );
    } catch (e) {
      print("Error during Apple sign in: $e");
      if (!context.mounted) return;

      // Show a snackbar instead of a dialog for errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign in failed. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleGoogleLogin(BuildContext context) async {
    try {
      // Clear offline mode preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('offline_mode', false);

      final authService = AuthService();
      final result = await authService.signInWithGoogle();

      print("Successfully signed in with Google. User: ${result.user?.email}");

      if (!context.mounted) return;

      // Navigate to main screen immediately after successful sign in
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainNavigationScaffold()),
            (route) => false,
      );
    } catch (e) {
      print("Error during Google sign in: $e");
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sign in failed. Please try again.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleOfflineMode(BuildContext context) async {
    // Save offline mode preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_mode', true);

    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const MainNavigationScaffold()),
          (route) => false,
    );
  }
}