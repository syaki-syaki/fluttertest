import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/models/repository.dart';
import 'package:testflutter/providers/github_service_provider.dart';
import 'package:testflutter/screens/issuelist.dart';
import 'package:testflutter/services/github_service.dart';

class UserRepositoryListScreen extends ConsumerStatefulWidget {
  final String keyword;
  final int stars;

  const UserRepositoryListScreen({
    super.key,
    required this.keyword,
    required this.stars,
  });

  @override
  ConsumerState<UserRepositoryListScreen> createState() =>
      _UserRepositoryListScreenState();
}

class _UserRepositoryListScreenState
    extends ConsumerState<UserRepositoryListScreen> {
  List<Repository> _repositories = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  String? _username;
  GitHubService? _service;

  @override
  void initState() {
    super.initState();
    ref.read(githubServiceProvider).whenData((s) {
      _service = s;
      _fetchUsernameAndLoadRepositories();
    });
  }

  Future<void> _fetchUsernameAndLoadRepositories() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('GitHubUsername');

    if (cached != null) {
      _username = cached;
      _loadUserRepositories();
      return;
    }

    final username = await _service?.getViewerUsername();
    if (username == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー名の取得に失敗しました。')),
        );
        Navigator.pop(context);
      }
      return;
    }

    _username = username;
    await prefs.setString('GitHubUsername', username);
    _loadUserRepositories();
  }

  Future<void> _loadUserRepositories() async {
    final service = _service;
    final username = _username;
    if (service == null || username == null) return;

    final repos = await service.searchRepositories(
      keyword: 'user:$username ${widget.keyword}',
      minStars: widget.stars,
      first: 25,
      after: null,
    );

    setState(() {
      _repositories = repos.map(Repository.fromJson).toList();
      _hasNextPage = _repositories.length == 25;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('あなたのリポジトリ一覧')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _repositories.length,
              itemBuilder: (_, index) {
                final repo = _repositories[index];
                return ListTile(
                  title: Text(repo.name),
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
                  _loadUserRepositories();
                }
                    : null,
                child: const Text('前のページ'),
              ),
              ElevatedButton(
                onPressed: _hasNextPage
                    ? () {
                  setState(() => _currentPage++);
                  _loadUserRepositories();
                }
                    : null,
                child: const Text('次のページ'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
