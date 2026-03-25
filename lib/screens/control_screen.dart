import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';

class ControlScreen extends StatelessWidget {
  const ControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttService>(
      builder: (context, mqtt, child) {
        final isOpen = mqtt.doorStatus.toLowerCase() == 'open';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Door Control'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isOpen ? Icons.lock_open : Icons.lock,
                  size: 140,
                  color: isOpen
                      ? const Color.fromRGBO(255, 152, 0, 1)
                      : const Color.fromARGB(255, 76, 175, 80),
                ),
                const SizedBox(height: 40),
                Text(
                  'Door: ${mqtt.doorStatus.toUpperCase()}',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock_open),
                      label: const Text('OPEN'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(255, 152, 0, 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      onPressed: () => mqtt.publishDoorCommand('OPEN'),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lock),
                      label: const Text('CLOSE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 76, 175, 80),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      onPressed: () => mqtt.publishDoorCommand('close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
