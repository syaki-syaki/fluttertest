// lib/screens/create_issue_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testflutter/services/github_service.dart';

class CreateIssueScreen extends ConsumerStatefulWidget {
  final String repositoryName;
  final String username;

  const CreateIssueScreen({
    super.key,
    required this.repositoryName,
    required this.username,
  });

  @override
  ConsumerState<CreateIssueScreen> createState() => _CreateIssueScreenState();
}

class _CreateIssueScreenState extends ConsumerState<CreateIssueScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _createIssue(GitHubService githubService) async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repositories = await githubService.getUserRepositories(widget.username);
      final targetRepo = repositories.firstWhere(
            (repo) => repo['name'] == widget.repositoryName,
        orElse: () => throw Exception('Repository not found'),
      );
      final repositoryId = targetRepo['id'];

      await githubService.createIssue(repositoryId, title, body);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('イシューが作成されました')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final githubServiceAsync = ref.watch(githubServiceProvider);

    return githubServiceAsync.when(
      data: (githubService) => Scaffold(
        appBar: AppBar(title: const Text('イシュー作成')),
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
                maxLines: 6,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _createIssue(githubService),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('作成'),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text('GitHubServiceの取得に失敗しました: $err')),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
