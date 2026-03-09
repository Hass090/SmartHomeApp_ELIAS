import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/mqtt_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Required top-level function for background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // You can add background message handling logic here if needed
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize local notifications (required for foreground display on Android)
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
    // iOS: DarwinInitializationSettings(), // uncomment later if you add iOS support
  );

  await flutterLocalNotificationsPlugin.initialize(
    settings: initializationSettings,
  );

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(create: (_) => MqttService(), child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token') != null;
  }

  // Send FCM token to your backend (only if user is logged in)
  Future<void> _registerFcmToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final authToken = prefs.getString('auth_token');

      if (authToken == null) {
        debugPrint('No auth token → skipping FCM registration');
        return;
      }

      final url = Uri.parse('http://192.168.1.145:5000/register_token');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('FCM token successfully registered on server');
      } else {
        debugPrint(
          'Failed to register FCM token: ${response.statusCode} → ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  @override
  void initState() {
    super.initState();

    // 1. Request notification permission (critical for Android 13+)
    _requestNotificationPermission();

    // 2. Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.messageId}');

      final notification = message.notification;
      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
          id: 0,
          title: notification.title ?? 'Smart Home',
          body: notification.body ?? 'New event',
          payload: message.data['payload'],
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'high_importance_channel',
              'High Importance Notifications',
              channelDescription: 'Notifications for smart home events',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: true,
            ),
          ),
        );
      }
    });

    // 3. Handle when user taps on notification and app opens from background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened via notification: ${message.data}');
      if (!mounted) return;

      // Example: navigate to history screen for motion or door events
      if (message.data['type'] == 'motion' || message.data['type'] == 'door') {
        Navigator.pushNamed(context, '/history');
      }
    });

    // 4. Get current FCM token and register it
    FirebaseMessaging.instance.getToken().then((token) {
      if (token != null) {
        debugPrint('FCM Token: $token');
        _registerFcmToken(token);
      }
    });

    // 5. Listen for token refresh (Firebase may rotate tokens)
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed: $newToken');
      _registerFcmToken(newToken);
    });
  }

  Future<void> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Notification permission granted');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      debugPrint('Provisional notification permission granted');
    } else {
      debugPrint('Notification permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Home PAP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.grey.shade50,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          scrolledUnderElevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: FutureBuilder<bool>(
        future: _isLoggedIn(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data == true
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/history': (context) => const HistoryScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Page not found'))),
        );
      },
    );
  }
}
