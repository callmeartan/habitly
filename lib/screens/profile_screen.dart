import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:habitly/services/auth_service.dart';
import 'package:habitly/screens/login_intro_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:habitly/providers/theme_provider.dart';
import 'package:path_provider/path_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;
  String? _imagePath;
  bool _isOfflineMode = true;
  String _userName = 'Guest User';
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authService.authStateChanges.listen((User? user) {
      if (mounted) {
        setState(() {
          _currentUser = user;
          _loadUserData(); // Reload user data when auth state changes
        });
      }
    });
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final user = _authService.currentUser;

    setState(() {
      _isOfflineMode = prefs.getBool('offline_mode') ?? true;
      _imagePath = prefs.getString('profile_image');
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? false;
      _darkModeEnabled = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

      if (!_isOfflineMode && user != null) {
        // First try to get the display name
        if (user.displayName != null && user.displayName!.isNotEmpty) {
          _userName = user.displayName!;
        }
        // If no display name, try to get the email
        else if (user.email != null && user.email!.isNotEmpty) {
          _userName = user.email!.split('@')[0]  // Get the part before @
              .split('.')  // Split by dots
              .map((word) => word[0].toUpperCase() + word.substring(1))  // Capitalize each word
              .join(' ');
        } else {
          _userName = prefs.getString('user_name') ?? 'Guest User';
        }
      } else {
        _userName = prefs.getString('user_name') ?? 'Guest User';
      }
    });
  }

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    } catch (e) {
      // Just handle the error silently
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        // Get the app's document directory for permanent storage
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String permanentPath = '${appDocDir.path}/$fileName';

        // Copy the image to permanent storage
        await File(image.path).copy(permanentPath);

        setState(() {
          _imagePath = permanentPath;
        });

        // Save the permanent path to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', permanentPath);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notifications_enabled', value);
  }

  Future<void> _toggleDarkMode(bool value) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    setState(() {
      _darkModeEnabled = value;
    });
    themeProvider.toggleTheme();
  }

  Future<void> _editProfile() async {
    final TextEditingController nameController = TextEditingController(text: _userName);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: GoogleFonts.poppins(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _userName = nameController.text;
                });

                // Save to SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('user_name', nameController.text);

                // Update Firebase display name if user is logged in
                if (_currentUser != null) {
                  await _currentUser!.updateDisplayName(nameController.text);
                }

                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          'Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onBackground,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: colorScheme.primary,
                          ),
                          onPressed: _editProfile,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: colorScheme.primary.withOpacity(0.2),
                                backgroundImage: _imagePath != null
                                    ? FileImage(File(_imagePath!))
                                    : null,
                                child: _imagePath == null
                                    ? Icon(
                                  Icons.person,
                                  size: 60,
                                  color: colorScheme.primary,
                                )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.photo_library,
                                    size: 20,
                                    color: colorScheme.onPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _userName,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    Text(
                      _isOfflineMode ? 'Offline Mode' : 'Apple Sign In',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onBackground.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Section
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSettingsTile(
                      icon: Icons.notifications,
                      title: 'Notifications',
                      subtitle: 'Enable push notifications',
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                      ),
                      colorScheme: colorScheme,
                    ),
                    _buildSettingsTile(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Toggle dark theme',
                      trailing: Switch(
                        value: _darkModeEnabled,
                        onChanged: _toggleDarkMode,
                      ),
                      colorScheme: colorScheme,
                    ),
                    _buildSettingsTile(
                      icon: Icons.backup,
                      title: 'Backup Data',
                      subtitle: 'Sync your data to the cloud',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      colorScheme: colorScheme,
                      onTap: () async {
                        // Show "Coming Soon" message
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Cloud backup coming soon!')),
                        );
                      },
                    ),
                    _buildSettingsTile(
                      icon: Icons.security,
                      title: 'Privacy',
                      subtitle: 'Manage your data and permissions',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      colorScheme: colorScheme,
                    ),
                    _buildSettingsTile(
                      icon: Icons.help_outline,
                      title: 'Feedback',
                      subtitle: 'Help us improve Habitly',
                      trailing: Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: colorScheme.onBackground.withOpacity(0.5),
                      ),
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),

              // Sign Out Button
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _handleSignOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.error,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(double.infinity, 0),
                  ),
                  child: Text(
                    'Log Out',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onError,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required ColorScheme colorScheme,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}