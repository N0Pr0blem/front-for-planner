class TaskFileResponse {
  final int id;
  final int taskId;
  final String name;
  final String type;

  TaskFileResponse({
    required this.id,
    required this.taskId,
    required this.name,
    required this.type,
  });

  factory TaskFileResponse.fromJson(Map<String, dynamic> json) {
    return TaskFileResponse(
      id: (json['id'] as num).toInt(),
      taskId: (json['taskId'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}