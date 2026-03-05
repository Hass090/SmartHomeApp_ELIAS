import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  String _notificationStatus = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final token = await FirebaseMessaging.instance.getToken();

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _notificationStatus = token != null ? 'Notifications enabled' : 'Token not received';
      } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _notificationStatus = 'Notifications blocked (permission denied)';
      } else {
        _notificationStatus = 'Permission not requested';
      }
      _isLoading = false;
    });
  }

  Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!mounted) return;

    setState(() {
      _notificationsEnabled = settings.authorizationStatus == AuthorizationStatus.authorized;
      _notificationStatus = settings.authorizationStatus == AuthorizationStatus.authorized
          ? 'Notifications enabled'
          : 'Permission not granted';
    });

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('FCM Token received: $token')),
        );
      }
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out?\n'
            'You will need to enter your email and password again.',
          ),
          actions: [
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

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have been logged out')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                const SizedBox(height: 16),

                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined, color: Colors.blue),
                  title: const Text('SmartHome ELIAS'),
                  subtitle: const Text('Smart home based on Raspberry Pi 5 and Raspberry Pi Pico 2W'),
                ),

                const Divider(height: 32, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Application version'),
                  subtitle: const Text('1.0.0 (beta)'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Version 1.0.0 • beta')),
                    );
                  },
                ),

                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Push Notifications'),
                  subtitle: Text(_notificationStatus),
                  trailing: Switch.adaptive(
                    value: _notificationsEnabled,
                    onChanged: (value) async {
                      if (value) {
                        await _requestPermission();
                      } else {
                        if (!mounted) return;
                        setState(() {
                          _notificationsEnabled = false;
                          _notificationStatus = 'Notifications turned off';
                        });
                      }
                    },
                  ),
                ),

                if (!_notificationsEnabled && !_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ElevatedButton(
                      onPressed: _requestPermission,
                      child: const Text('Request Permission Again'),
                    ),
                  ),

                const Divider(height: 32, indent: 16, endIndent: 16),

                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.redAccent),
                  title: const Text(
                    'Log Out',
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