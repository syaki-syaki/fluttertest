// lib/graphql/queries.dart
const String getViewerQuery = '''
  query GetViewer {
    viewer {
      login
    }
  }
''';

const String getUserRepositoriesQuery = '''
  query GetUserRepositories(\$username: String!) {
    user(login: \$username) {
      repositories(first: 10) {
        nodes {
          id
          name
          url
          description
          owner {
            login
          }
        }
      }
    }
  }
''';
const String searchRepositoriesQuery = r'''
  query SearchRepositories($query: String!, $first: Int!, $after: String) {
    search(query: $query, type: REPOSITORY, first: $first, after: $after) {
      edges {
        node {
          ... on Repository {
            id
            name
            description
            url
            owner {
              login
            }
          }
        }
      }
    }
  }
''';


const String getIssuesQuery = '''
  query GetIssues(\$username: String!, \$repositoryName: String!, \$first: Int, \$after: String) {
    repository(owner: \$username, name: \$repositoryName) {
      issues(first: \$first, after: \$after) {
        nodes {
          id
          title
          body
          url
        }
      }
    }
  }
''';
