import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/mqtt_service.dart';

class FanControlScreen extends StatelessWidget {
  const FanControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MqttService>(
      builder: (context, mqtt, child) {
        final isFanOn = mqtt.fanStatus == 'ON';
        final isAutoMode = mqtt.fanMode == 'AUTO';
        final temp = mqtt.temperature;

        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: const Text('Fan Control'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Auto mode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: isAutoMode,
                          activeThumbColor: Colors.orange,
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: Colors.grey.withValues(
                            alpha: 0.5,
                          ),
                          onChanged: (value) {
                            mqtt.publishFanCommand(value ? 'AUTO' : 'MANUAL');
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Container(
                      key: ValueKey<String>(mqtt.fanStatus),
                      height: 280,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isFanOn ? Icons.air : Icons.mode_fan_off,
                            size: 140,
                            color: isFanOn
                                ? const Color.fromRGBO(255, 152, 0, 1)
                                : const Color.fromARGB(255, 76, 175, 80),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Fan: ${mqtt.fanStatus}',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Temp: $temp°C',
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.grey,
                            ),
                          ),
                          if (isAutoMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(
                                'Manual buttons disabled in Auto mode',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.orange.withValues(alpha: 0.8),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  Opacity(
                    opacity: isAutoMode ? 0.45 : 1.0,
                    child: IgnorePointer(
                      ignoring: isAutoMode,
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.power_settings_new,
                                size: 28,
                              ),
                              label: const Text(
                                'ON',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(
                                  255,
                                  152,
                                  0,
                                  1,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => mqtt.publishFanCommand('ON'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(
                                Icons.power_settings_new,
                                size: 28,
                              ),
                              label: const Text(
                                'OFF',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  76,
                                  175,
                                  80,
                                ),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 20,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: () => mqtt.publishFanCommand('OFF'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Temperature History',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: true),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: (mqtt.temperatureHistory.length - 1).toDouble(),
                        minY: mqtt.temperatureHistory.isEmpty
                            ? 0
                            : mqtt.temperatureHistory.reduce(
                                    (a, b) => a < b ? a : b,
                                  ) -
                                  2,
                        maxY: mqtt.temperatureHistory.isEmpty
                            ? 40
                            : mqtt.temperatureHistory.reduce(
                                    (a, b) => a > b ? a : b,
                                  ) +
                                  2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: mqtt.temperatureHistory
                                .asMap()
                                .entries
                                .map((e) => FlSpot(e.key.toDouble(), e.value))
                                .toList(),
                            isCurved: true,
                            color: Colors.orange,
                            barWidth: 4,
                            dotData: const FlDotData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
