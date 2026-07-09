// ignore_for_file: deprecated_member_use, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AiChatWidget extends StatefulWidget {
  const AiChatWidget({super.key});

  @override
  State<AiChatWidget> createState() => _AiChatWidgetState();
}

class _AiChatWidgetState extends State<AiChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKeyController.text = prefs.getString('google_api_key') ?? '';
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_api_key', key);
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    final apiKey = _apiKeyController.text.trim();

    if (message.isEmpty) return;
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon masukkan Google API Key')),
      );
      return;
    }

    await _saveApiKey(apiKey);

    setState(() {
      _messages.add({'role': 'user', 'content': message});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      // Diagnostic logging
      print("Mengirim request ke backend...");
      
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5001/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'api_key': apiKey,
          'odometer_km': 60000.0,
          'months_since_service': 1.0,
          'dtc_code': 'None'
        }),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _messages.add({'role': 'assistant', 'content': data['reply']});
        });
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Error: ${response.statusCode} - ${response.body}'});
        });
      }
    } catch (e) {
      print("Error detail: $e");
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Gagal terhubung ke backend: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.2), blurRadius: 4)],
      ),
      child: Column(
        children: [
          TextField(
            controller: _apiKeyController,
            decoration: const InputDecoration(labelText: 'Google API Key', border: OutlineInputBorder()),
            obscureText: true,
            onChanged: _saveApiKey,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200,
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return ListTile(
                  title: Text(msg['role'] == 'user' ? 'Anda' : 'Asisten'),
                  subtitle: Text(msg['content']!),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: TextField(controller: _messageController, decoration: const InputDecoration(hintText: 'Tanyakan masalah...'))),
              IconButton(icon: _isLoading ? const CircularProgressIndicator() : const Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
