import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedType = 'all';
  final List<String> _filterOptions = [
    'All',
    'Access',
    'Alert',
    'System',
    'Error',
  ];

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) throw Exception('No token');

      final uri = Uri.parse('http://192.168.1.145:5000/history?limit=50')
          .replace(
            queryParameters: _selectedType == 'all'
                ? null
                : {'type': _selectedType.toLowerCase()},
          );

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() => _events = data.cast<Map<String, dynamic>>());
      } else if (response.statusCode == 401) {
        await prefs.remove('auth_token');
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  IconData _getIconForType(String message, String type) {
    final msg = message.toLowerCase();
    final t = type.toLowerCase();

    if (msg.contains('open')) return Icons.lock_open;
    if (msg.contains('close')) return Icons.lock;
    if (msg.contains('opened')) return Icons.door_front_door;
    if (msg.contains('closed')) return Icons.door_front_door;
    if (msg.contains('motion')) return Icons.directions_run;
    if (t.contains('alert')) return Icons.warning_amber_rounded;
    if (t.contains('control')) return Icons.settings_remote;
    return Icons.info_outline;
  }

  Color _getColorForType(String message, String type) {
    final msg = message.toLowerCase();
    if (msg.contains('open')) return Colors.green;
    if (msg.contains('close') || msg.contains('closed')) return Colors.red;
    if (msg.contains('motion') || msg.contains('alert')) return Colors.orange;
    return Colors.white70;
  }

  String _formatType(String type) {
    final t = type.toLowerCase();
    if (t == 'access' || t == 'control') return 'Control';
    if (t == 'alert') return 'Alert';
    return type;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Event History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedType,
            dropdownColor: const Color(0xFF1C1C1E),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            underline: const SizedBox(),
            items: _filterOptions
                .map(
                  (value) => DropdownMenuItem(
                    value: value.toLowerCase(),
                    child: Text(value),
                  ),
                )
                .toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedType = newValue);
                _fetchHistory();
              }
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              )
            : _events.isEmpty
            ? const Center(
                child: Text(
                  'No events yet',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  final event = _events[index];
                  final message = event['message'] ?? '';
                  final timestamp = event['timestamp'] ?? '';
                  final type = event['type'] ?? 'unknown';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                          _getIconForType(message, type),
                          size: 40,
                          color: _getColorForType(message, type),
                        ),
                        title: Text(
                          message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${_formatType(type)} • $timestamp',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
