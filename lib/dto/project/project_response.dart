class ProjectResponse {
  final int id;
  final String name;
  final String creationDate;
  final int storageId;

  ProjectResponse({
    required this.id,
    required this.name,
    required this.creationDate,
    required this.storageId,
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    return ProjectResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      creationDate: json['creation_date'] as String,
      storageId: json['storage_id'] as int,
    );
  }
}