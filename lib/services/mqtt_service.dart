import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class MqttService with ChangeNotifier {
  MqttServerClient? client;
  bool isConnected = false;

  // Easy-to-use variables
  String temperature = '--';
  String humidity = '--';
  String pressure = '--';
  String doorStatus = 'unknown';
  bool motionDetected = false;

  MqttService() {
    _connect();
  }

  Future<void> _connect() async {
    const broker = '192.168.1.145';
    const port = 1883;
    final clientId = 'flutter_app_${DateTime.now().millisecondsSinceEpoch}';

    client = MqttServerClient(broker, clientId);
    client!.port = port;
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.onConnected = _onConnected;
    client!.onDisconnected = _onDisconnected;
    client!.onSubscribed = (topic) => debugPrint('Subscribed to: $topic');

    final connMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      await client!.connect('pico', '123mqtt456b');
      debugPrint('MQTT successfully connected!');
    } catch (e) {
      debugPrint('MQTT connection error: $e');
      isConnected = false;
      notifyListeners();
    }
  }

  void _onConnected() {
    debugPrint('MQTT connected!');
    isConnected = true;
    notifyListeners();

    // Your real topics
    client!.subscribe(
      'smarthome/pico/environment/temperature',
      MqttQos.atLeastOnce,
    );
    client!.subscribe(
      'smarthome/pico/environment/humidity',
      MqttQos.atLeastOnce,
    );
    client!.subscribe(
      'smarthome/pico/environment/pressure',
      MqttQos.atLeastOnce,
    );
    client!.subscribe('smarthome/pico/security/door', MqttQos.atLeastOnce);
    client!.subscribe('smarthome/pico/security/motion', MqttQos.atLeastOnce);

    client!.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final payload = MqttPublishPayload.bytesToStringAsString(
        recMess.payload.message,
      );
      final topic = c[0].topic;

      debugPrint('MQTT received → $topic : $payload');

      _updateValue(topic, payload);
      notifyListeners();
    });
  }

  void _updateValue(String topic, String payload) {
    if (topic.contains('temperature')) temperature = payload;
    if (topic.contains('humidity')) humidity = payload;
    if (topic.contains('pressure')) pressure = payload;
    if (topic.contains('door')) doorStatus = payload.toUpperCase();

    if (topic.contains('motion')) {
      final lower = payload.toLowerCase().trim();
      motionDetected = lower != 'quiet' && lower != 'false' && lower != '0';
    }
  }

  void _onDisconnected() {
    debugPrint('MQTT disconnected');
    isConnected = false;
    notifyListeners();
  }

  void publishDoorCommand(String command) {
    if (client == null || !isConnected) {
      debugPrint('MQTT is not connected');
      return;
    }
    final builder = MqttClientPayloadBuilder();
    builder.addString(command);

    client!.publishMessage(
      'smarthome/pico/control/door',
      MqttQos.atLeastOnce,
      builder.payload!,
    );
    debugPrint('Door command sent: $command');
  }

  @override
  void dispose() {
    client?.disconnect();
    super.dispose();
  }
}
