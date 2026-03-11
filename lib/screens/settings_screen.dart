import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _permissionGranted = false;
  String _notificationStatus = 'Loading...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (!mounted) return;
    setState(() {
      _permissionGranted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      _notificationsEnabled =
          prefs.getBool('notifications_enabled') ?? _permissionGranted;
      _notificationStatus = _notificationsEnabled
          ? 'Notifications enabled'
          : 'Notifications disabled';
      _isLoading = false;
    });
  }

  Future<void> _registerFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;
      final url = Uri.parse('http://192.168.1.145:5000/register_token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );
      if (response.statusCode == 200) {
        debugPrint('Token registered on server');
      }
    } catch (e) {
      debugPrint('Register token error: $e');
    }
  }

  Future<void> _unregisterFcmToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');
      if (authToken == null) return;
      final url = Uri.parse('http://192.168.1.145:5000/unregister_token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) {
        debugPrint('Token unregistered from server');
      }
    } catch (e) {
      debugPrint('Unregister token error: $e');
    }
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final messaging = FirebaseMessaging.instance;
    setState(() => _notificationsEnabled = value);
    if (value) {
      final settings = await messaging.requestPermission();
      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      await prefs.setBool('notifications_enabled', granted);
      if (granted) {
        final token = await messaging.getToken();
        if (token != null) await _registerFcmToken(token);
        _notificationStatus = 'Notifications enabled';
      } else {
        _notificationStatus = 'Permission not granted';
      }
    } else {
      await _unregisterFcmToken();
      await messaging.deleteToken();
      await prefs.setBool('notifications_enabled', false);
      _notificationStatus = 'Notifications disabled';
    }
    if (mounted) setState(() {});
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C1E),
          title: const Text('Log Out', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Are you sure you want to log out?\nYou will need to sign in again with your credentials.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Log Out', style: TextStyle(color: Colors.red)),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      },
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (!context.mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('You have been logged out')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.black,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.smart_toy_outlined,
                      size: 32,
                      color: Colors.white,
                    ),
                    title: const Text('SmartHome ELIAS'),
                    subtitle: const Text('Raspberry Pi 5 + Pico 2W'),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        title: const Text('Push Notifications'),
                        subtitle: Text(_notificationStatus),
                        value: _notificationsEnabled,
                        onChanged: _toggleNotifications,
                        secondary: const Icon(Icons.notifications_outlined),
                        activeThumbColor: Colors.white,
                      ),
                      if (!_permissionGranted)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton.icon(
                            onPressed: () => _toggleNotifications(true),
                            icon: const Icon(Icons.notifications_active),
                            label: const Text('Request Permission'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.info_outline),
                        title: const Text('App Version'),
                        subtitle: const Text('1.0.0 (beta)'),
                        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('SmartHome ELIAS 1.0.0 • beta'),
                          ),
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white24),
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.redAccent,
                        ),
                        title: const Text(
                          'Log Out',
                          style: TextStyle(color: Colors.redAccent),
                        ),
                        onTap: () => _showLogoutDialog(context),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Text(
                    '© 2026 SmartHome ELIAS',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
    );
  }
}
