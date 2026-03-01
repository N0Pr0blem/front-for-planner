class RepositoryFileResponse {
  final int id;
  final int storageId;
  final String type;
  final String name;
  final String creationDate;

  RepositoryFileResponse({
    required this.id,
    required this.storageId,
    required this.type,
    required this.name,
    required this.creationDate
  });

  factory RepositoryFileResponse.fromJson(Map<String, dynamic> json) {
    return RepositoryFileResponse(
      id: json['id'] as int,
      storageId: json['storage_id'] as int,
      type: json['mime_type'] as String,
      name: json['name'] as String,
      creationDate: json['creation_date'] as String
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