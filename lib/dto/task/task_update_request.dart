class TaskUpdateRequest {
  final String name;
  final String urgency;
  final String complexity;
  final String status;
  final String description;

  TaskUpdateRequest({
    required this.name,
    required this.urgency,
    required this.complexity,
    required this.status,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'urgency': urgency,
      'complexity': complexity,
      'status': status,
      'description': description,
    };
  }
}