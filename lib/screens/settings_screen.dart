import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _showLogoutDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?\nYou will need to enter your email and password again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Log Out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        );
      },
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');

    if (!context.mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have been logged out of your account.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const SizedBox(height: 16),

          ListTile(
            leading: const Icon(Icons.smart_toy_outlined, color: Colors.blue),
            title: const Text('SmartHome ELIAS'),
            subtitle: const Text('Smarthome based on Raspberry Pi 5 and Raspberry Pi Pico 2W'),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Application version'),
            subtitle: const Text('1.0.0 (beta)'),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Версия 1.0.0 • beta')),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Push-notifications'),
            subtitle: const Text('Will be available after Firebase is configured.'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            enabled: false,
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.redAccent),
            ),
            onTap: () => _showLogoutDialog(context),
          ),

          const SizedBox(height: 40),

          Center(
            child: Text(
              '© 2026 SmartHome ELIAS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}