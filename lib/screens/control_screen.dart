import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttService>(
      builder: (context, mqtt, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Door Control')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Door: ${mqtt.doorStatus.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('OPEN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                      ),
                      onPressed: () => mqtt.publishDoorCommand('OPEN'), // UPPER
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('CLOSE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 18,
                        ),
                      ),
                      onPressed: () =>
                          mqtt.publishDoorCommand('close'), // lower
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Text(
                  mqtt.isConnected ? 'MQTT connected' : 'MQTT disconnected',
                  style: TextStyle(
                    color: mqtt.isConnected ? Colors.green : Colors.red,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
