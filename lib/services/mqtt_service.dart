import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService with ChangeNotifier {
  late MqttServerClient client;
  bool isConnected = false;
  Map<String, String> latestValues =
      {}; // door, temperature, humidity, motion...

  MqttService() {
    _connect();
  }

  Future<void> _connect() async {
    const broker = '192.168.1.145';
    const port = 1883;
    final clientId = 'flutter_home_${DateTime.now().millisecondsSinceEpoch}';

    client = MqttServerClient(broker, clientId);
    client.port = port;
    client.logging(on: true);
    client.keepAlivePeriod = 60;
    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;
    client.onSubscribed = (topic) => debugPrint('Subscribed to $topic');

    try {
      await client.connect('pico', '123mqtt456b');
    } catch (e) {
      debugPrint('MQTT connect error: $e');
      client.disconnect();
      isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    debugPrint('MQTT connected!');
    isConnected = true;
    notifyListeners();

    client.subscribe(
      'smarthome/pico/environment/temperature',
      MqttQos.atLeastOnce,
    );
    client.subscribe(
      'smarthome/pico/environment/humidity',
      MqttQos.atLeastOnce,
    );
    client.subscribe(
      'smarthome/pico/environment/pressure',
      MqttQos.atLeastOnce,
    );
    client.subscribe('smarthome/pico/security/door', MqttQos.atLeastOnce);
    client.subscribe('smarthome/pico/security/motion', MqttQos.atLeastOnce);
    // face, lock, etc...

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = c[0].topic;

      debugPrint('MQTT → $topic : $pt');

      latestValues[topic] = pt;
      notifyListeners();
    });
  }

  void _onDisconnected() {
    debugPrint('MQTT disconnected');
    isConnected = false;
    notifyListeners();
  }

  void publishDoorCommand(String command) {
    if (!isConnected) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(command.toUpperCase()); // OPEN / CLOSED
    client.publishMessage(
      'smarthome/pico/control/door',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
  }

  @override
  void dispose() {
    client.disconnect();
    super.dispose();
  }
}
