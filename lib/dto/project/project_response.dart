class ProjectResponse {
  final int id;
  final String name;

  ProjectResponse({
    required this.id,
    required this.name,
  });

  factory ProjectResponse.fromJson(Map<String, dynamic> json) {
    return ProjectResponse(
      id: json['id'] as int,
      name: json['name'] as String,
    );
  }
}