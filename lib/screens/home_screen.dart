import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'control_screen.dart';
import 'history_screen.dart';
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

  late MqttService _mqttService;

  @override
  void initState() {
    super.initState();
    _mqttService = MqttService();
    _mqttService.addListener(_updateUIFromMqtt);

    _fetchStatus();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _fetchStatus());

    debugPrint('MQTT service initialized');
  }

  void _updateUIFromMqtt() {
    setState(() {

    });
  }

  Future<void> _fetchStatus() async {
    if (_httpStatus.isEmpty) {
      setState(() => _isLoading = true);
    }

    setState(() => _errorMessage = null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        throw Exception('No token found. Please login again.');
      }

      final response = await http.get(
        Uri.parse('http://192.168.1.145:5000/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint('HTTP status: $decoded');
        setState(() {
          _httpStatus = decoded;
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('auth_token');
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
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
    _mqttService.removeListener(_updateUIFromMqtt);
    _mqttService.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tempStr =
        _mqttService.latestValues['smarthome/pico/environment/temperature'] ??
        (_httpStatus['temperature']?.toStringAsFixed(1) ?? '--');
    final humStr =
        _mqttService.latestValues['smarthome/pico/environment/humidity'] ??
        (_httpStatus['humidity']?.toStringAsFixed(0) ?? '--');
    final pressStr =
        _mqttService.latestValues['smarthome/pico/environment/pressure'] ??
        (_httpStatus['pressure']?.toStringAsFixed(0) ?? '--');

    final doorRaw =
        _mqttService.latestValues['smarthome/pico/security/door'] ??
        _httpStatus['door'] as String?;
    final doorLower = doorRaw?.toLowerCase();
    final isDoorOpen = doorLower == 'open' || doorRaw == 'OPEN';
    final doorDisplay = isDoorOpen ? 'Open' : 'Closed';
    final doorColor = isDoorOpen ? Colors.orange : Colors.green;

    final motionRaw =
        _mqttService.latestValues['smarthome/pico/security/motion'];
    final isMotionDetected =
        motionRaw == 'DETECTED' || _httpStatus['motion_detected'] == true;

    final lastAccess = _httpStatus['last_access'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Home'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _mqttService.isConnected ? Colors.green : Colors.red,
              ),
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchStatus),
        ],
      ),
      body:
          _isLoading && _httpStatus.isEmpty && _mqttService.latestValues.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Current Conditions Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const Text(
                              'Current Conditions',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInfoItem(
                                  icon: Icons.thermostat,
                                  label: 'Temperature',
                                  value: '$tempStr °C',
                                ),
                                _buildInfoItem(
                                  icon: Icons.water_drop,
                                  label: 'Humidity',
                                  value: '$humStr %',
                                ),
                                _buildInfoItem(
                                  icon: Icons.compress,
                                  label: 'Pressure',
                                  value: '$pressStr hPa',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Security Card
                    Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
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
                            const SizedBox(height: 12),

                            // Door
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

                            // Motion
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
                                style: TextStyle(
                                  color: isMotionDetected ? Colors.red : null,
                                ),
                              ),
                            ),

                            // Last Access
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

                    const SizedBox(height: 24),

                    // Buttons
                    ElevatedButton.icon(
                      icon: const Icon(Icons.door_sliding),
                      label: const Text('Door Control'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ControlScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    ElevatedButton.icon(
                      icon: const Icon(Icons.history),
                      label: const Text('Event History'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 40, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}
