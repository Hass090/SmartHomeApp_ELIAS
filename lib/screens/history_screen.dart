import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _selectedType = 'all'; // 'all', 'access', 'alert', 'system', 'error' и т.д.

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
          .replace(queryParameters: _selectedType == 'all' ? null : {'type': _selectedType.toLowerCase()});

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _events = data.cast<Map<String, dynamic>>();
        });
      } else if (response.statusCode == 401) {
        await prefs.remove('auth_token');
        if (mounted) Navigator.pushReplacementNamed(context, '/');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatType(String type) {
    switch (type.toLowerCase()) {
      case 'access':
        return 'Access';
      case 'alert':
        return 'Alert';
      case 'system':
        return 'System';
      case 'error':
        return 'Error';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event History'),
        actions: [
          DropdownButton<String>(
            value: _selectedType,
            items: _filterOptions.map((String value) {
              return DropdownMenuItem<String>(
                value: value.toLowerCase(),
                child: Text(value),
              );
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() => _selectedType = newValue);
                _fetchHistory();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchHistory,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                : _events.isEmpty
                    ? const Center(child: Text('No events yet'))
                    : ListView.builder(
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final timestamp = event['timestamp'] ?? '';
                          final type = _formatType(event['type'] ?? 'unknown');
                          final message = event['message'] ?? '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getColorForType(type),
                              child: Text(type[0].toUpperCase()),
                            ),
                            title: Text(message),
                            subtitle: Text('$type • $timestamp'),
                            isThreeLine: true,
                          );
                        },
                      ),
      ),
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'access':
        return Colors.green;
      case 'alert':
        return Colors.red;
      case 'error':
        return Colors.orange;
      default:
        return Colors.blueGrey;
    }
  }
}