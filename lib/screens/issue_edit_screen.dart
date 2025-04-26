// lib/screens/edit_issue_screen.dart
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter/material.dart';
import 'package:testflutter/services/github_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditIssueScreen extends StatefulWidget {
  final String issueId;
  final String repositoryName;
  final String issueTitle;
  final String issueBody;

  const EditIssueScreen({
    super.key,
    required this.issueId,
    required this.repositoryName,
    required this.issueTitle,
    required this.issueBody,
  });

  @override
  State<EditIssueScreen> createState() => _EditIssueScreenState();
}

class _EditIssueScreenState extends State<EditIssueScreen> {
  late TextEditingController _titleController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.issueTitle);
    _bodyController = TextEditingController(text: widget.issueBody);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }


  Future<void> _saveIssue() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('GitHubToken') ?? '';

      if (token.isEmpty) {
        throw Exception('トークンが保存されていません');
      }

      final client = GraphQLClient(
        link: HttpLink(
          'https://api.github.com/graphql',
          defaultHeaders: {
            'Authorization': 'Bearer $token',
          },
        ),
        cache: GraphQLCache(store: InMemoryStore()),
      );

      final githubService = GitHubService(client: client);

      await githubService.updateIssue(
        widget.issueId,
        title,
        body,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イシューを編集しました')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('編集に失敗しました: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('イシュー編集')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: '本文'),
              maxLines: 5,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveIssue,
                  child: const Text('保存'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('キャンセル'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
