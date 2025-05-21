import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testflutter/providers/github_service_provider.dart';
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
  ConsumerState<CreateIssueScreen> createState() =>
      _CreateIssueScreenState();
}

class _CreateIssueScreenState extends ConsumerState<CreateIssueScreen> {
  final _title = TextEditingController();
  final _body  = TextEditingController();
  bool _submitting = false;

  Future<void> _create() async {
    if (_title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイトルを入力してください')),
      );
      return;
    }

    setState(() => _submitting = true);
    final service = ref.read(githubServiceProvider).value;
    if (service == null) return;

    try {
      final repos = await service.getUserRepositories(widget.username);
      final target =
      repos.firstWhere((e) => e['name'] == widget.repositoryName);
      await service.createIssue(
        target['id'],
        _title.text.trim(),
        _body.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イシューを作成しました')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エラー: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('イシュー作成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'タイトル')),
            const SizedBox(height: 12),
            TextField(
              controller: _body,
              decoration: const InputDecoration(labelText: '本文'),
              maxLines: 6,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitting ? null : _create,
              child: _submitting
                  ? const CircularProgressIndicator()
                  : const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }
}
