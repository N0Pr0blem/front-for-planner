class TaskCreateRequest {
  final String name;
  final String urgency;
  final String complexity;
  final int projectId;
  final String description;

  TaskCreateRequest({
    required this.name,
    required this.urgency,
    required this.complexity,
    required this.projectId,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'urgency': urgency,
      'complexity': complexity,
      'project_id': projectId,
      'description': description,
    };
  }
}