import 'package:your_app_name/dto/task/task_detail_response.dart';

class TaskResponse {
  final int id;
  final String name;
  final bool isCompleted;
  final String assignBy;
  final String? assignByImage;
  final String? status; // ← теперь опциональный

  TaskResponse({
    required this.id,
    required this.name,
    required this.isCompleted,
    required this.assignBy,
    this.assignByImage,
    this.status, // ← опциональный
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
      status: json['status'] as String?, // ← безопасное приведение к String?
    );
  }

  TaskResponse.fromDetail(TaskDetailResponse detail)
      : id = detail.id,
        name = detail.name,
        isCompleted = detail.isCompleted,
        assignBy = detail.assignedBy.fullName,
        status = detail.status,
        assignByImage = detail.assignedBy.profileImage;

  bool get isAssigned => assignBy != 'null null';

  // Вспомогательный метод для отображения статуса
  String get displayStatus {
    switch (status?.toUpperCase()) {
      case 'TO_DO': return 'Нужно сделать';
      case 'IN_PROGRESS': return 'В работе';
      case 'REVIEW': return 'На код ревью';
      case 'IN_TEST': return 'В тестировании';
      case 'DONE': return 'Готова';
      default: return status ?? 'Не задан';
    }
  }
}