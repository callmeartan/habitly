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
import 'package:flutter/services.dart';
import '../services/firebase_sync_service.dart';
import '../repositories/habit_repository.dart';
import '../repositories/task_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:habitly/repositories/task_repository.dart' show TaskRepository;
import 'package:habitly/repositories/habit_repository.dart' show HabitRepository;
import 'package:habitly/services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onRefresh;

  const ProfileScreen({
    Key? key,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  User? _currentUser;
  String? _imagePath;
  bool _isOfflineMode = true;
  String _userName = 'Guest User';
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  final FirebaseSyncService _firebaseSyncService = FirebaseSyncService();
  final HabitRepository _habitRepository = HabitRepository();
  final TaskRepository _taskRepository = TaskRepository();
  bool _isSyncing = false;
  late AnimationController _syncAnimationController;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadUserData();
    _setupAuthListener();
    _animationController.forward();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _syncAnimationController.dispose();
    super.dispose();
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
      setState(() => _isLoading = true);
      HapticFeedback.mediumImpact();

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final Directory appDocDir = await getApplicationDocumentsDirectory();
        final String fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String permanentPath = '${appDocDir.path}/$fileName';

        await File(image.path).copy(permanentPath);

        setState(() {
          _imagePath = permanentPath;
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profile_image', permanentPath);
      }
    } catch (e) {
      print('Failed to update profile picture: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    try {
      // Request permissions if enabling
      if (value && !_notificationsEnabled) {
        final hasPermission = await _notificationService.requestPermissions();
        if (!hasPermission) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Notification permissions denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = value;
      });

      // Update SharedPreferences
      await prefs.setBool('notifications_enabled', _notificationsEnabled);

      // Cancel all notifications if disabled
      if (!_notificationsEnabled) {
        await _notificationService.cancelAllNotifications();
      }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _notificationsEnabled
                    ? 'Notifications enabled'
                    : 'Notifications disabled'
            ),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle notifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _syncData() async {
    if (!_firebaseSyncService.isUserSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to sync data')),
      );
      return;
    }

    setState(() => _isSyncing = true);
    _syncAnimationController.repeat();

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Syncing data...')),
      );

      // Perform sync
      await Future.wait([
        _habitRepository.syncWithCloud(),
        _taskRepository.syncWithCloud(),
      ]);

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data synced successfully!')),
      );

      // Refresh the UI
      widget.onRefresh?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sync failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
        _syncAnimationController.stop();
      }
    }
  }

  Future<void> _showHelpSupport() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildHelpTile(
              icon: Icons.email_outlined,
              title: 'Contact Support',
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'support@habitly.app',
                  queryParameters: {
                    'subject': 'Habitly Support Request',
                  },
                );
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                }
              },
            ),
            _buildHelpTile(
              icon: Icons.description_outlined,
              title: 'FAQ',
              onTap: () async {
                final url = Uri.parse('https://github.com/callmeartan/habitly-support/blob/main/README.md');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
            ),
            _buildHelpTile(
              icon: Icons.feedback_outlined,
              title: 'Send Feedback',
              onTap: () => _showFeedbackDialog(),
            ),
            _buildHelpTile(
              icon: Icons.info_outline,
              title: 'About Habitly',
              onTap: () => _showAboutDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(
        title,
        style: GoogleFonts.poppins(),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Future<void> _showFeedbackDialog() async {
    final TextEditingController feedbackController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Send Feedback',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Tell us what you think...',
            hintStyle: GoogleFonts.poppins(),
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              // TODO: Implement feedback submission
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thank you for your feedback!')),
              );
            },
            child: Text('Submit', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Habitly',
        applicationVersion: '1.0.0',
        applicationIcon: Image.asset(
          'assets/icon/icon.png',
          width: 50,
          height: 50,
        ),
        children: [
          const SizedBox(height: 16),
          Text(
            'A habit tracking app to help you build better habits and achieve your goals.',
            style: GoogleFonts.poppins(),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2024 Habitly. All rights reserved.',
            style: GoogleFonts.poppins(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Confirm Logout',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Before logging out:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Any unsaved data will be lost',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.sync_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Consider syncing your data first',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _syncData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Sync Data First',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleSignOut();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Logout Anyway',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLoginTransition() async {
    // Check if there's existing offline data
    final hasOfflineData = await Future.wait([
      _habitRepository.hasLocalData(),
      _taskRepository.hasLocalData(),
    ]).then((results) => results.any((hasData) => hasData));

    if (!mounted) return;

    // Show a detailed confirmation dialog if there's offline data
    final shouldProceed = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        bool shouldMergeData = true; // Default to merging data

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            hasOfflineData ? 'Existing Data Found' : 'Switch to Online Mode',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasOfflineData) ...[
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have existing offline data',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StatefulBuilder(
                  builder: (context, setState) => CheckboxListTile(
                    value: shouldMergeData,
                    onChanged: (value) {
                      setState(() => shouldMergeData = value ?? true);
                    },
                    title: Text(
                      'Keep my existing data',
                      style: GoogleFonts.poppins(),
                    ),
                    subtitle: Text(
                      'Your offline data will be merged with your cloud account',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ),
                const SizedBox(height: 8),
                if (!shouldMergeData)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your offline data will be permanently deleted',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ] else ...[
                Text(
                  'Would you like to sign in to access cloud features?',
                  style: GoogleFonts.poppins(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sync your data across devices',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                {'proceed': true, 'mergeData': shouldMergeData},
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldProceed != null && shouldProceed['proceed'] == true && mounted) {
      if (hasOfflineData && shouldProceed['mergeData']) {
        // Save offline data before transitioning
        await _habitRepository.prepareForLogin();
        await _taskRepository.prepareForLogin();
      } else if (hasOfflineData) {
        // Clear offline data if user chose not to merge
        await _habitRepository.clearLocalData();
        await _taskRepository.clearLocalData();
      }

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final progressColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _fadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _fadeAnimation.value,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: progressColor,
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(
                                  Icons.edit,
                                  color: progressColor.withOpacity(0.7),
                                ),
                                onPressed: _editProfile,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                CircleAvatar(
                                  radius: 60,
                                  backgroundColor: progressColor.withOpacity(0.1),
                                  backgroundImage: _imagePath != null
                                      ? FileImage(File(_imagePath!))
                                      : null,
                                  child: _imagePath == null
                                      ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: progressColor.withOpacity(0.7),
                                  )
                                      : null,
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.shadowColor.withOpacity(0.1),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.camera_alt,
                                      size: 20,
                                      color: progressColor.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _userName,
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: progressColor,
                            ),
                          ),
                          Text(
                            _isOfflineMode ? 'Offline Mode' : 'Online Account',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: progressColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSettingsSection(theme, progressColor),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsSection(ThemeData theme, Color progressColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: progressColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingCard(
            theme,
            progressColor,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
            ),
          ),
          _buildSettingCard(
            theme,
            progressColor,
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: _darkModeEnabled,
              onChanged: _toggleDarkMode,
            ),
          ),
          _buildSettingCard(
            theme,
            progressColor,
            icon: Icons.sync_outlined,
            title: 'Sync Data',
            onTap: _syncData,
            trailing: _isSyncing
                ? SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              ),
            )
                : Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: progressColor.withOpacity(0.5),
            ),
          ),
          _buildSettingCard(
            theme,
            progressColor,
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: _showHelpSupport,
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: progressColor.withOpacity(0.5),
            ),
          ),
          _buildSettingCard(
            theme,
            progressColor,
            icon: _isOfflineMode ? Icons.login_outlined : Icons.logout_outlined,
            title: _isOfflineMode ? 'Sign In' : 'Sign Out',
            onTap: _isOfflineMode ? _handleLoginTransition : _showLogoutConfirmation,
            isDestructive: !_isOfflineMode,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
      ThemeData theme,
      Color progressColor, {
        required IconData icon,
        required String title,
        VoidCallback? onTap,
        Widget? trailing,
        bool isDestructive = false,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive
                      ? theme.colorScheme.error
                      : progressColor.withOpacity(0.7),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: isDestructive
                          ? theme.colorScheme.error
                          : progressColor,
                    ),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}