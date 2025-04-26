// lib/screens/issue_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testflutter/models/issue.dart';
import 'package:testflutter/services/github_service.dart';
import 'issue_edit_screen.dart';
import 'issuecrate.dart';

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
  bool _hasNextPage = true;
  bool _isLoading = false;
  GitHubService? _cachedService;
  String? _endCursor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final asyncService = ref.watch(githubServiceProvider);
    asyncService.whenData((service) {
      if (_cachedService == null) {
        _cachedService = service;
        print('[DEBUG] GitHubService インスタンスを初期化');
        _loadIssues(service);
      }
    });
  }

  Future<void> _loadIssues(GitHubService githubService) async {
    setState(() => _isLoading = true);
    print('[DEBUG] Issueロード開始 (page: $_currentPage, endCursor: $_endCursor)');

    try {
      final result = await githubService.getIssues(
        widget.username,
        widget.repositoryName,
        25,
        after: _currentPage > 1 ? _endCursor : null,
      );

      print('[DEBUG] 取得したデータ: ${result.length} 件');
      for (var i = 0; i < result.length; i++) {
        print('[DEBUG] Issue[$i]: ${result[i]['title']} (${result[i]['id']})');
      }

      final issuesData = result.map((json) => Issue.fromJson(json)).toList();

      setState(() {
        _issues = issuesData;
        _hasNextPage = issuesData.length == 25;
        _isLoading = false;
        if (_hasNextPage && issuesData.isNotEmpty) {
          _endCursor = issuesData.last.id;
          print('[DEBUG] 次のページ用 endCursor: $_endCursor');
        }
      });
    } catch (e, stack) {
      print('[ERROR] Issue取得失敗: $e');
      print('[STACK] $stack');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _deleteIssue(String issueId) async {
    if (_cachedService == null) return;

    try {
      print('[DEBUG] イシュー削除リクエスト: $issueId');
      await _cachedService!.deleteIssue(issueId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('イシューを削除しました')),
      );
      _loadIssues(_cachedService!);
    } catch (e) {
      print('[ERROR] イシュー削除失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('削除に失敗しました: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final githubServiceAsync = ref.watch(githubServiceProvider);

    return githubServiceAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) {
        print('[ERROR] GitHubServiceProvider エラー: $err');
        return Scaffold(body: Center(child: Text('エラー: $err')));
      },
      data: (_) => Scaffold(
        appBar: AppBar(title: const Text('Issue一覧')),
        body: Column(
          children: [
            Expanded(
              child: _issues.isEmpty
                  ? const Center(child: Text('Issueが見つかりません'))
                  : ListView.builder(
                itemCount: _issues.length,
                padding: const EdgeInsets.all(8),
                itemBuilder: (context, index) {
                  final issue = _issues[index];
                  return Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      title: Text(issue.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(issue.body ?? ''),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () async {
                              print('[DEBUG] 編集開始: ${issue.id}');
                              final result = await Navigator.push(
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
                              if (result == true) {
                                _loadIssues(_cachedService!);
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteIssue(issue.id),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentPage > 1 && !_isLoading
                      ? () {
                    setState(() => _currentPage--);
                    print('[DEBUG] 前のページ ($_currentPage)');
                    _loadIssues(_cachedService!);
                  }
                      : null,
                  child: const Text('前のページ'),
                ),
                ElevatedButton(
                  onPressed: _hasNextPage && !_isLoading
                      ? () {
                    setState(() => _currentPage++);
                    print('[DEBUG] 次のページ ($_currentPage)');
                    _loadIssues(_cachedService!);
                  }
                      : null,
                  child: const Text('次のページ'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                print('[DEBUG] 新規Issue作成画面へ');
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateIssueScreen(
                      repositoryName: widget.repositoryName,
                      username: widget.username,
                    ),
                  ),
                );
                if (result == true) _loadIssues(_cachedService!);
              },
              child: const Text('新規Issue作成'),
            ),
          ],
        ),
      ),
    );
  }
}
