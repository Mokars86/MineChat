import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/auth_service.dart';
import 'auth/sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 60,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User Name
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // User Email
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Profile Options
                  _buildProfileOption(
                    context,
                    Icons.person,
                    'Edit Profile',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit Profile not implemented yet')),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    Icons.notifications,
                    'Notifications',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications not implemented yet')),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    Icons.security,
                    'Privacy & Security',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy & Security not implemented yet')),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    Icons.help,
                    'Help & Support',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Help & Support not implemented yet')),
                      );
                    },
                  ),
                  _buildProfileOption(
                    context,
                    Icons.info,
                    'About',
                    () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('About not implemented yet')),
                      );
                    },
                  ),
                  Consumer<ThemeProvider>(
                    builder: (context, themeProvider, _) {
                      return SwitchListTile(
                        title: const Text('Dark Mode'),
                        secondary: Icon(
                          themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: AppTheme.primaryColor,
                        ),
                        value: themeProvider.isDarkMode,
                        onChanged: (_) {
                          themeProvider.toggleTheme();
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Logout Button
                  ElevatedButton.icon(
                    onPressed: () => _showLogoutDialog(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileOption(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Logout
              final authService = AuthService();
              await authService.signOut();

              // Navigate to login screen
              if (context.mounted) {
                Navigator.of(context).pop(); // Dismiss loading dialog
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const SignInScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
