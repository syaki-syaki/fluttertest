import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:testflutter/graphql/queries.graphql.dart';

class GitHubService {
  final GraphQLClient client;
  GitHubService({required this.client});

  /* ---------- クエリ ---------- */
  Future<String?> getViewerUsername() async {
    final r = await client.query(
      QueryOptions(document: documentNodeQueryGetViewer),
    );
    if (r.hasException) return null;
    return r.data?['viewer']?['login'];
  }

  Future<List<Map<String, dynamic>>> searchRepositories({
    required String keyword,
    required int minStars,
    int first = 25,
    String? after,
  }) async {
    final q = [
      if (keyword.trim().isNotEmpty) keyword.trim(),
      if (minStars > 0) 'stars:>=$minStars',
      'sort:stars-desc'
    ].join(' ');

    final r = await client.query(
      QueryOptions(
        document: documentNodeQuerySearchRepositories,
        variables: {'query': q, 'first': first, 'after': after},
      ),
    );
    if (r.hasException) {
      print('[ERROR] searchRepositories 失敗: ${r.exception}');
      return [];
    }
    return List<Map<String, dynamic>>.from(
      (r.data?['search']?['edges'] as List?)?.map((e) => e?['node']) ?? [],
    );
  }

  Future<List<Map<String, dynamic>>> getIssues(
      String username, String repo, int first,
      {String? after}) async {
    final r = await client.query(
      QueryOptions(
        document: documentNodeQueryGetIssues,
        variables: {
          'username': username,
          'repositoryName': repo,
          'first': first,
          'after': after,
        },
      ),
    );
    if (r.hasException) return [];
    return List<Map<String, dynamic>>.from(
      r.data?['repository']?['issues']?['nodes'] ?? [],
    );
  }
}
