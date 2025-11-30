class RepositoryFileResponse {
  final int id;
  final int projectRepoId;
  final String type;
  final String name;

  RepositoryFileResponse({
    required this.id,
    required this.projectRepoId,
    required this.type,
    required this.name,
  });

  factory RepositoryFileResponse.fromJson(Map<String, dynamic> json) {
    return RepositoryFileResponse(
      id: json['id'] as int,
      projectRepoId: json['projectRepoId'] as int,
      type: json['type'] as String,
      name: json['name'] as String,
    );
  }

  String get fileExtension {
    final parts = name.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : '';
  }

  String get displayName {
    return name.length > 30 ? '${name.substring(0, 30)}...' : name;
  }
}