
import 'package:your_app_name/dto/task/task_detail_response.dart';

class TaskResponse {
  final int id;
  final String name;
  final bool isCompleted;
  final String assignBy;
  final String? assignByImage; 

  TaskResponse({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.assignBy,
    this.assignByImage,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      isCompleted: json['is_completed'] as bool,
      assignBy: json['assign_by'] as String,
      assignByImage: json['assign_by_image'] != 'null'
          ? json['assign_by_image'] as String?
          : null,
    );
  }

  TaskResponse.fromDetail(TaskDetailResponse detail)
      : id = detail.id,
        name = detail.name,
        isCompleted = detail.isCompleted,
        assignBy = detail.assignedBy.fullName,
        assignByImage = detail.assignedBy.profileImage;

  bool get isAssigned => assignBy != 'null null';
}