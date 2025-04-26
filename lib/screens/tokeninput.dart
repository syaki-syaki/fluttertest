// lib/screens/token_input_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/screens/home_screen.dart';

class TokenInputScreen extends StatefulWidget {
  const TokenInputScreen({super.key});

  @override
  State<TokenInputScreen> createState() => _TokenInputScreenState();
}

class _TokenInputScreenState extends State<TokenInputScreen> {
  final TextEditingController _tokenController = TextEditingController();

  Future<void> _saveTokenAndNavigate() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('トークンを入力してください')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('GitHubToken', token);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHubトークン入力')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'GitHubトークン',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveTokenAndNavigate,
              child: const Text('保存して次へ'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }
}
