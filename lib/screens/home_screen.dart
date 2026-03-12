import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'control_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import '../services/mqtt_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> _httpStatus = {};
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchStatus());
  }

  Future<void> _fetchStatus() async {
    if (_httpStatus.isEmpty) setState(() => _isLoading = true);
    setState(() => _errorMessage = null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No token found');

      final response = await http.get(
        Uri.parse('http://192.168.1.145:5000/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _httpStatus = jsonDecode(response.body);
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('auth_token');
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load status: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildTeslaIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      splashColor: Colors.white.withAlpha(30),
      highlightColor: Colors.white.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Icon(icon, size: 44, color: Colors.white),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = Provider.of<MqttService>(context);

    final tempStr = _httpStatus['temperature']?.toStringAsFixed(1) ?? '--';
    final humStr = _httpStatus['humidity']?.toStringAsFixed(0) ?? '--';
    final pressStr = _httpStatus['pressure']?.toStringAsFixed(0) ?? '--';

    final doorRaw = mqtt.doorStatus;
    final isDoorOpen = doorRaw.toLowerCase() == 'open';
    final doorDisplay = isDoorOpen ? 'Open' : 'Closed';
    final doorColor = isDoorOpen
        ? const Color.fromRGBO(255, 152, 0, 1)
        : const Color.fromARGB(255, 76, 175, 80);

    final isMotionDetected =
        mqtt.motionDetected || _httpStatus['motion_detected'] == true;
    final lastAccess = _httpStatus['last_access'] as String?;

    final statusText = mqtt.isConnected ? 'Connected' : 'Disconnected';
    final statusColor = mqtt.isConnected ? Colors.green : Colors.red;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'ELIAS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: mqtt.isConnected
                ? TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.2),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeInOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.green,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withAlpha(150),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                  ),
          ),
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _fetchStatus,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: _isLoading && _httpStatus.isEmpty && tempStr == '--'
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ELIAS',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$tempStr °C',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$humStr % • $pressStr hPa',
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Container(
                      height: 240,
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.home_filled,
                              size: 160,
                              color: Colors.white70,
                            ),
                            Text(
                              'Smart Home',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildTeslaIcon(
                            Icons.lock,
                            'Door',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ControlScreen(),
                              ),
                            ),
                          ),
                          _buildTeslaIcon(Icons.thermostat, 'Climate', () {}),
                          _buildTeslaIcon(Icons.lightbulb, 'Lights', () {}),
                          _buildTeslaIcon(
                            Icons.waves,
                            'History',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Security card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Security',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ListTile(
                                leading: Icon(
                                  Icons.door_front_door,
                                  color: doorColor,
                                  size: 36,
                                ),
                                title: const Text('Door'),
                                subtitle: Text(
                                  doorDisplay,
                                  style: TextStyle(
                                    color: doorColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListTile(
                                leading: Icon(
                                  Icons.sensors,
                                  color: isMotionDetected
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 36,
                                ),
                                title: const Text('Motion'),
                                subtitle: Text(
                                  isMotionDetected ? 'Detected' : 'No motion',
                                ),
                              ),
                              if (lastAccess != null)
                                ListTile(
                                  leading: const Icon(Icons.login, size: 36),
                                  title: const Text('Last Access'),
                                  subtitle: Text(lastAccess),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
