
class Repository {
  final String id;
  final String name;
  final String? description;
  final String htmlUrl;
  final String owner;

  Repository({
    required this.id,
    required this.name,
    this.description,
    required this.htmlUrl,
    required this.owner,
  });

  factory Repository.fromJson(Map<String, dynamic> json) {
    return Repository(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      htmlUrl: json['url'],
      owner: json['owner']['login'],
    );
  }
}
