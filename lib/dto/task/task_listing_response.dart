import 'task_response.dart';

class TaskListingResponse {
  final List<TaskResponse> tasks;
  final int pages;
  final int size;
  final bool archived;
  final int pageNumber;

  TaskListingResponse({
    required this.tasks,
    required this.pages,
    required this.size,
    required this.archived,
    required this.pageNumber,
  });

  factory TaskListingResponse.fromJson(Map<String, dynamic> json) {
    return TaskListingResponse(
      tasks: (json['tasks'] as List)
          .map((item) => TaskResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      pages: json['pages'] as int,
      size: json['size'] as int,
      archived: json['archived'] as bool,
      pageNumber: json['pageNumber'] as int,
    );
  }
}