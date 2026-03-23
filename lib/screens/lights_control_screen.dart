import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/mqtt_service.dart';

class LightsControlScreen extends StatelessWidget {
  const LightsControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttService>(
      builder: (context, mqtt, child) {
        final isOn = mqtt.lightStatus == 'ON';

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Lights Control'),
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
                  isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                  size: 140,
                  color: isOn
                      ? const Color.fromRGBO(255, 152, 0, 1)
                      : const Color.fromARGB(255, 76, 175, 80),
                ),
                const SizedBox(height: 40),
                Text(
                  'Light: ${mqtt.lightStatus}',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
                const SizedBox(height: 60),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lightbulb),
                      label: const Text('ON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromRGBO(255, 152, 0, 1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      onPressed: () => mqtt.publishLightCommand('ON'),
                    ),
                    const SizedBox(width: 30),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('OFF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 76, 175, 80),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      onPressed: () => mqtt.publishLightCommand('OFF'),
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
