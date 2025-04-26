// lib/graphql/mutations.dart

// ✅ イシューを作成するミューテーション
const String createIssueMutation = r'''
  mutation CreateIssue(\$repositoryId: ID!, \$title: String!, \$body: String) {
    createIssue(input: {repositoryId: \$repositoryId, title: \$title, body: \$body}) {
      issue {
        id
        title
        body
      }
    }
  }
''';

// ✅ イシューを更新するミューテーション
const String updateIssueMutation = r'''
  mutation UpdateIssue(\$id: ID!, \$title: String!, \$body: String) {
    updateIssue(input: {id: \$id, title: \$title, body: \$body}) {
      issue {
        id
        title
        body
      }
    }
  }
''';

// ✅ イシューを削除するミューテーション
const String deleteIssueMutation = r'''
  mutation DeleteIssue(\$issueId: ID!) {
    deleteIssue(input: {issueId: \$issueId}) {
      clientMutationId
    }
  }
''';
