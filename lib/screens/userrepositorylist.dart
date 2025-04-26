import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/models/repository.dart';
import 'package:testflutter/services/github_service.dart';
import 'package:testflutter/screens/issuelist.dart'; // ← Issuelist が定義されているファイルを import

final githubServiceProvider = Provider<GitHubService>((ref) {
  throw UnimplementedError('GitHubService must be overridden');
});

class UserRepositoryListScreen extends ConsumerStatefulWidget {
  final String repositoryName;
  final String keyword;

  const UserRepositoryListScreen({
    super.key,
    required this.repositoryName,
    required this.keyword,
  });

  @override
  ConsumerState<UserRepositoryListScreen> createState() => _UserRepositoryListScreenState();
}

class _UserRepositoryListScreenState extends ConsumerState<UserRepositoryListScreen> {
  List<Repository> _repositories = [];
  int _currentPage = 1;
  bool _hasNextPage = true;
  String? _username;

  @override
  void initState() {
    super.initState();
    _fetchUsernameAndLoadRepositories();
  }

  Future<void> _fetchUsernameAndLoadRepositories() async {
    final githubService = ref.read(githubServiceProvider);
    final prefs = await SharedPreferences.getInstance();

    try {
      final username = await githubService.getViewerUsername();
      if (username != null) {
        setState(() => _username = username);
        await prefs.setString('GitHubUsername', username);
        _loadUserRepositories();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ユーザー名の取得に失敗しました。')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('エラー: $e')),
      );
    }
  }

  Future<void> _loadUserRepositories() async {
    if (_username == null) return;
    final githubService = ref.read(githubServiceProvider);
    final result = await githubService.getUserRepositories(_username!);

    setState(() {
      _repositories = result.map((repoJson) => Repository.fromJson(repoJson)).toList();
      _hasNextPage = _repositories.length == 10;
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
              itemBuilder: (context, index) {
                final repo = _repositories[index];
                return ListTile(
                  title: Text(repo.name),
                  subtitle: Text(repo.description ?? 'No description'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => IssueListScreen(
                          repositoryName: repo.name,
                          username: repo.owner, // .login は不要、ownerがString型ならこれでOK
                        ),
                      ),
                    );
                  },

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
