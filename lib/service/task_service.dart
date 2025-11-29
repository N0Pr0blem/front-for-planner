import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/task/task_response.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/trekking_response.dart';
import '../dto/task/task_update_request.dart';
import '../dto/task/task_create_request.dart';
import '../utils/token_storage.dart';

class TaskService {
  static const String baseUrl = 'http://localhost:8080';

  static Future<List<TaskResponse>> getTasks(int projectId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/browse');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => TaskResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  static Future<TaskDetailResponse> getTaskDetails(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('No auth token');

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return TaskDetailResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load task details: ${response.statusCode}');
    }
  }

  static Future<TrekkingResponse> getTrekking(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('No auth token');

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/trekking');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return TrekkingResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load trekking: ${response.statusCode}');
    }
  }

  static Future<void> updateTaskStatus(int taskId, String newStatus) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task status: ${response.statusCode}');
    }
  }

  // В класс TaskService добавьте:
  static Future<void> deleteTrekking(int trekkingId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/trekking/$trekkingId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete trekking: ${response.statusCode}');
    }
  }

  static Future<void> addTrekking({
    required String date,
    required double hours,
    required int projectId,
    required int taskId,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/trekking');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'date': date,
        'hours': hours,
        'project_id': projectId,
        'task_id': taskId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add trekking: ${response.statusCode}');
    }
  }

  static Future<void> assignTaskToMe({
    required int projectId,
    required int taskId,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/task/$taskId');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign task: ${response.statusCode}');
    }
  }

  static Future<String> getTaskDescription(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/description');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['message'] as String? ?? '';
    } else {
      throw Exception(
          'Failed to load task description: ${response.statusCode}');
    }
  }

  static Future<void> updateTask({
    required int taskId,
    required TaskUpdateRequest updateRequest,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateRequest.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  static Future<TaskDetailResponse> createTask({
    required TaskCreateRequest createRequest,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(createRequest.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TaskDetailResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
  }
}
