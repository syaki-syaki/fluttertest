import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:testflutter/models/repository.dart';
import 'package:testflutter/providers/github_service_provider.dart';
import 'package:testflutter/screens/issuelist.dart';
import 'package:testflutter/services/github_service.dart';

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
    ref.listen<AsyncValue<GitHubService>>(githubServiceProvider,
            (_, next) => next.whenData(_initIfNeeded));
  }

  void _initIfNeeded(GitHubService service) {
    if (_cachedService == null) {
      _cachedService = service;
      _loadRepositories();
    }
  }

  Future<void> _loadRepositories() async {
    final service = _cachedService;
    if (service == null) return;

    final repos = await service.searchRepositories(
      keyword: widget.keyword,
      minStars: widget.stars,
      first: 25,
      after: _currentPage > 1 ? _endCursor : null,
    );

    setState(() {
      _repositories = repos.map(Repository.fromJson).toList();
      _hasNextPage = repos.length == 25;
      _endCursor = _hasNextPage ? repos.last['id'] : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final serviceAsync = ref.watch(githubServiceProvider);

    return serviceAsync.when(
      loading: () =>
      const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('エラー: $e'))),
      data: (_) => Scaffold(
        appBar: AppBar(title: const Text('リポジトリ一覧')),
        body: Column(
          children: [
            Expanded(
              child: _repositories.isEmpty
                  ? const Center(child: Text('リポジトリが見つかりません'))
                  : ListView.builder(
                padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: _repositories.length,
                itemBuilder: (_, index) {
                  final repo = _repositories[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      title: Text(repo.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(repo.description ?? 'No description'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => IssueListScreen(
                            username: repo.owner,
                            repositoryName: repo.name,
                          ),
                        ),
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
                  onPressed: _currentPage > 1
                      ? () {
                    setState(() => _currentPage--);
                    _loadRepositories();
                  }
                      : null,
                  child: const Text('前のページ'),
                ),
                ElevatedButton(
                  onPressed: _hasNextPage
                      ? () {
                    setState(() => _currentPage++);
                    _loadRepositories();
                  }
                      : null,
                  child: const Text('次のページ'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
