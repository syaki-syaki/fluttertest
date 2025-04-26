import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testflutter/models/repository.dart';
import 'package:testflutter/services/github_service.dart';
import 'package:testflutter/screens/issuelist.dart';

class RepositoryListScreen extends ConsumerStatefulWidget {
  final String repositoryName;
  final String keyword;
  final int stars;

  const RepositoryListScreen({
    super.key,
    required this.repositoryName,
    required this.keyword,
    required this.stars,
  });

  @override
  ConsumerState<RepositoryListScreen> createState() =>
      _RepositoryListScreenState();
}

class _RepositoryListScreenState extends ConsumerState<RepositoryListScreen> {
  List<Repository> _repositories = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  String? _endCursor;
  GitHubService? _cachedService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final asyncService = ref.watch(githubServiceProvider);
    asyncService.whenData((service) {
      if (_cachedService == null) {
        _cachedService = service;
        _loadRepositories(service);
      }
    });
  }
  Future<void> _loadRepositories(GitHubService githubService) async {
    try {
      print('[DEBUG] 検索条件: repositoryName="${widget.repositoryName}", keyword="${widget.keyword}" ページ: $_currentPage');

      // 空白でも必ず動くクエリを組み立てる
      String searchQuery;
      if (widget.keyword.trim().isEmpty) {
        searchQuery = widget.repositoryName.trim().isNotEmpty
            ? '${widget.repositoryName} in:name'
            : 'stars:>0';
      } else {
        searchQuery = '${widget.keyword} in:name,description';
      }


      final result = await githubService.searchRepositories(
        searchQuery,
        25,
        after: _currentPage > 1 ? _endCursor : null,
      );

      print('[DEBUG] 検索結果(キーワードマッチ後): ${result.length} 件');

      List<Map<String, dynamic>> filteredResult = result;

      print('[DEBUG] 取得リポジトリ一覧:');
      for (var repo in filteredResult) {
        print('リポジトリ名: ${repo['name']}');
      }

// 🔥 フィルターは repositoryName が空じゃないときだけ適用する




      print('[DEBUG] リポジトリ名絞り込み後: ${filteredResult.length} 件');

      setState(() {
        _repositories = filteredResult.map((repoJson) => Repository.fromJson(repoJson)).toList();
        _hasNextPage = result.length == 25;
        if (_hasNextPage && result.isNotEmpty) {
          _endCursor = result.last['id'];
        }
      });
    } catch (e, stackTrace) {
      print('[ERROR] リポジトリ取得中の例外: $e');
      print('[STACK] $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラーが発生しました: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final githubServiceAsync = ref.watch(githubServiceProvider);

    return githubServiceAsync.when(
      data: (githubService) {
        return Scaffold(
          appBar: AppBar(title: const Text('リポジトリ一覧')),
          body: Column(
            children: [
              Expanded(
                child: _repositories.isEmpty
                    ? const Center(child: Text('リポジトリが見つかりません'))
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  itemCount: _repositories.length,
                  itemBuilder: (context, index) {
                    final repo = _repositories[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          repo.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(repo.description ?? 'No description'),
                            const SizedBox(height: 6),
                            Text(
                              'Owner: \${repo.owner}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => IssueListScreen(
                                repositoryName: repo.name,
                                username: repo.owner,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _currentPage > 1
                        ? () {
                      setState(() => _currentPage--);
                      _loadRepositories(githubService);
                    }
                        : null,
                    child: const Text('前のページ'),
                  ),
                  ElevatedButton(
                    onPressed: _hasNextPage
                        ? () {
                      setState(() => _currentPage++);
                      _loadRepositories(githubService);
                    }
                        : null,
                    child: const Text('次のページ'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('エラー: \$err'))),
    );
  }
}