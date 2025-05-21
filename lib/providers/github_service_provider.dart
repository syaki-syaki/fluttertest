import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:testflutter/services/github_service.dart';

final githubServiceProvider = FutureProvider<GitHubService>((ref) async {
  final prefs  = await SharedPreferences.getInstance();
  final token  = prefs.getString('github_token') ?? '';

  final link   = HttpLink(
    'https://api.github.com/graphql',
    defaultHeaders: {'Authorization': 'bearer $token'},
  );

  final client = GraphQLClient(
    link:  link,
    cache: GraphQLCache(store: InMemoryStore()),
  );

  return GitHubService(client: client);
});
