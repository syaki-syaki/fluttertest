import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/screens/repositorylist.dart';
import 'package:testflutter/screens/userrepositorylist.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final repositoryNameController = TextEditingController();
  final keywordController = TextEditingController();
  final starsController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GitHub検索')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: repositoryNameController,
              decoration: const InputDecoration(labelText: 'リポジトリ名'),
            ),
            TextField(
              controller: keywordController,
              decoration: const InputDecoration(labelText: 'キーワード'),
            ),
            TextField(
              controller: starsController,
              decoration: const InputDecoration(labelText: 'スター数'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final repositoryName = repositoryNameController.text.trim();
                final keyword = keywordController.text.trim();

                 keywordController.text.trim();
                final stars = int.tryParse(starsController.text.trim()) ?? 0;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RepositoryListScreen(
                      repositoryName: repositoryName,
                      keyword: keyword,
                      stars: stars,
                    ),
                  ),
                );
              },
              child: const Text('GitHub全体検索'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final repositoryName = repositoryNameController.text.trim();
                final keyword = keywordController.text.trim();
                     keywordController.text.trim();

                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('GitHubToken') ?? '';

                if (token.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('トークンが設定されていません。')),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UserRepositoryListScreen(
                      repositoryName: repositoryName,
                      keyword: keyword,
                    ),
                  ),
                );
              },
              child: const Text('ユーザーリポジトリ検索'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    repositoryNameController.dispose();
    keywordController.dispose();
    starsController.dispose();
    super.dispose();
  }
}
