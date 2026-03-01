class TaskFileResponse {
  final int id;
  final int storageId;
  final String name;
  final String type;
  final String creationDate;

  TaskFileResponse({
    required this.id,
    required this.storageId,
    required this.name,
    required this.type,
    required this.creationDate
  });

  factory TaskFileResponse.fromJson(Map<String, dynamic> json) {
    return TaskFileResponse(
      id: (json['id'] as num).toInt(),
      storageId: (json['storage_id'] as num).toInt(),
      name: json['name'] as String,
      type: json['mime_type'] as String,
      creationDate: json['creation_date'] as String
    );
  }
}