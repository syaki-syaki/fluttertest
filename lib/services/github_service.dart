import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/graphql/queries.dart';
import 'package:testflutter/graphql/mutations.dart';

class GitHubService {
  final GraphQLClient client;

  GitHubService({required this.client});

  Future<String?> getViewerUsername() async {
    final result = await client.query(QueryOptions(
      document: gql(getViewerQuery),
    ));
    if (result.hasException) return null;
    return result.data?['viewer']?['login'];
  }

  Future<List<Map<String, dynamic>>> getUserRepositories(String username) async {
    final result = await client.query(QueryOptions(
      document: gql(getUserRepositoriesQuery),
      variables: {'username': username},
    ));
    if (result.hasException) return [];
    return List<Map<String, dynamic>>.from(
      result.data?['user']?['repositories']?['nodes'] ?? [],
    );
  }

  Future<List<Map<String, dynamic>>> getRepository(String username) async {
    final result = await client.query(QueryOptions(
      document: gql(getUserRepositoriesQuery),
      variables: {'username': username},
    ));
    if (result.hasException) return [];
    return List<Map<String, dynamic>>.from(
      result.data?['user']?['repositories']?['nodes'] ?? [],
    );
  }

  Future<List<Map<String, dynamic>>> searchRepositories(String query, int first, {String? after}) async {
    final result = await client.query(QueryOptions(
      document: gql(searchRepositoriesQuery),
      variables: {
        'query': query,
        'first': first,
        'after': after,
      },
    ));
    if (result.hasException) {
      print('[ERROR] searchRepositories失敗: ${result.exception.toString()}');
      return [];
    }

    return List<Map<String, dynamic>>.from(
      (result.data?['search']?['edges'] as List?)?.map((e) => e?['node']) ?? [],
    );
  }

  Future<List<Map<String, dynamic>>> getIssues(
      String username, String repositoryName, int first,
      {String? after}) async {
    final result = await client.query(QueryOptions(
      document: gql(getIssuesQuery),
      variables: {
        'username': username,
        'repositoryName': repositoryName,
        'first': first,
        'after': after,
      },
    ));
    if (result.hasException) return [];
    return List<Map<String, dynamic>>.from(
      result.data?['repository']?['issues']?['nodes'] ?? [],
    );
  }

  Future<void> createIssue(String repositoryId, String title, String? body) async {
    await client.mutate(MutationOptions(
      document: gql(createIssueMutation),
      variables: {
        'repositoryId': repositoryId,
        'title': title,
        'body': body,
      },
    ));
  }

  Future<bool> deleteIssue(String issueId) async {
    final result = await client.mutate(MutationOptions(
      document: gql(deleteIssueMutation),
      variables: {'issueId': issueId},
    ));
    if (result.hasException) return false;
    return result.data?['deleteIssue'] != null;
  }

  Future<void> updateIssue(String issueId, String title, String body) async {
    await client.mutate(MutationOptions(
      document: gql(updateIssueMutation),
      variables: {
        'id': issueId,
        'title': title,
        'body': body,
      },
    ));
  }
}

final githubServiceProvider = FutureProvider<GitHubService>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('GitHubToken');

  if (token == null || token.isEmpty) {
    throw Exception('GitHub token not found');
  }

  final link = HttpLink(
    'https://api.github.com/graphql',
    defaultHeaders: {
      'Authorization': 'Bearer $token',
    },
  );

  final client = GraphQLClient(
    link: link,
    cache: GraphQLCache(store: InMemoryStore()),
  );

  return GitHubService(client: client);
});
