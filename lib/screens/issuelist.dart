import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testflutter/models/issue.dart';
import 'package:testflutter/providers/github_service_provider.dart';
import 'create_issue_screen.dart';
import 'edit_issue_screen.dart';
import 'package:testflutter/services/github_service.dart';

class IssueListScreen extends ConsumerStatefulWidget {
  final String username;
  final String repositoryName;

  const IssueListScreen({
    super.key,
    required this.username,
    required this.repositoryName,
  });

  @override
  ConsumerState<IssueListScreen> createState() => _IssueListScreenState();
}

class _IssueListScreenState extends ConsumerState<IssueListScreen> {
  List<Issue> _issues = [];
  int _currentPage = 1;
  bool _hasNext = true;
  bool _loading = false;
  String? _endCursor;
  GitHubService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listen<AsyncValue<GitHubService>>(githubServiceProvider,
            (_, next) => next.whenData(_initIfNeeded));
  }

  void _initIfNeeded(GitHubService s) {
    if (_service == null) {
      _service = s;
      _load();
    }
  }

  Future<void> _load() async {
    if (_service == null) return;
    setState(() => _loading = true);

    final data = await _service!.getIssues(
      widget.username,
      widget.repositoryName,
      25,
      after: _currentPage > 1 ? _endCursor : null,
    );
    final list = data.map(Issue.fromJson).toList();

    setState(() {
      _issues = list;
      _hasNext = list.length == 25;
      _endCursor = _hasNext ? list.last.id : null;
      _loading = false;
    });
  }

  Future<void> _delete(String id) async {
    if (_service == null) return;
    await _service!.deleteIssue(id);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(githubServiceProvider);

    return serviceAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (_) => Scaffold(
        appBar: AppBar(title: const Text('Issue一覧')),
        body: Column(
          children: [
            Expanded(
              child: _issues.isEmpty
                  ? const Center(child: Text('Issueが見つかりません'))
                  : ListView.builder(
                itemCount: _issues.length,
                itemBuilder: (_, i) {
                  final issue = _issues[i];
                  return ListTile(
                    title: Text(issue.title),
                    subtitle: Text(issue.body ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditIssueScreen(
                                  issueId: issue.id,
                                  repositoryName: widget.repositoryName,
                                  issueTitle: issue.title,
                                  issueBody: issue.body ?? '',
                                ),
                              ),
                            );
                            if (updated == true) _load();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _delete(issue.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed:
                  _currentPage > 1 && !_loading ? () { setState(() => _currentPage--); _load(); } : null,
                  child: const Text('前のページ'),
                ),
                ElevatedButton(
                  onPressed:
                  _hasNext && !_loading ? () { setState(() => _currentPage++); _load(); } : null,
                  child: const Text('次のページ'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateIssueScreen(
                      repositoryName: widget.repositoryName,
                      username: widget.username,
                    ),
                  ),
                );
                if (created == true) _load();
              },
              child: const Text('新規Issue作成'),
            ),
          ],
        ),
      ),
    );
  }
}
