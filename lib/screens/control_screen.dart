import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  late MqttServerClient client;
  bool isConnected = false;
  String currentDoorStatus = 'unknown';

  @override
  void initState() {
    super.initState();
    _connectAndListen();
  }

  Future<void> _connectAndListen() async {
    const broker = '192.168.1.145';
    const port = 1883;
    final clientId = 'flutter_control_${DateTime.now().millisecondsSinceEpoch}';

    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onConnected = () {
      setState(() => isConnected = true);
      debugPrint('MQTT → connected');

      client.subscribe('smarthome/pico/security/door', MqttQos.atLeastOnce);

      client.updates!.listen((messages) {
        final message = messages[0].payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          message.payload.message,
        );

        debugPrint('Received → ${messages[0].topic} : $payload');

        if (messages[0].topic == 'smarthome/pico/security/door') {
          setState(() {
            currentDoorStatus = payload;
          });
        }
      });
    };

    client.onDisconnected = () => setState(() => isConnected = false);

    try {
      await client.connect('pico', '123mqtt456b');
    } catch (e) {
      debugPrint('MQTT connection error: $e');
      client.disconnect();
    }
  }

  void _sendDoorCommand(String command) {
    if (!isConnected) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('MQTT is not connected!')));
      return;
    }

    final builder = MqttClientPayloadBuilder();
    builder.addString(command);

    client.publishMessage(
      'smarthome/pico/control/door',
      MqttQos.atLeastOnce,
      builder.payload!,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Sent: $command')));
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Door control')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Door: ${currentDoorStatus.toUpperCase()}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                  onPressed: () => _sendDoorCommand('OPEN'),
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
                  onPressed: () => _sendDoorCommand('close'),
                ),
              ],
            ),

            const SizedBox(height: 40),

            Text(
              isConnected ? 'MQTT connected' : 'MQTT disabled',
              style: TextStyle(
                color: isConnected ? Colors.green : Colors.red,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
