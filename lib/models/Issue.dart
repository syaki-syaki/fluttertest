// lib/models/issue.dart

class Issue {
  final String id;
  final String title;
  final String? body;

  Issue({
    required this.id,
    required this.title,
    this.body,
  });

  factory Issue.fromJson(Map<String, dynamic> json) {
    return Issue(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
    };
  }
}
