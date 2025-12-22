import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/project/project_response.dart';
import '../utils/token_storage.dart';

class ProjectService {
  static const String baseUrl = 'http://10.193.60.191:8080';

  Future<List<ProjectResponse>> getProjects() async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/project');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);

      // Проверяем, если ответ null или не является списком
      if (jsonData == null) {
        return []; // Возвращаем пустой список вместо исключения
      }

      if (jsonData is! List) {
        // Если ответ не список, проверяем, может быть это Map с сообщением
        if (jsonData is Map<String, dynamic>) {
          // Проверяем, если есть сообщение о том, что проектов нет
          if (jsonData.containsKey('message') &&
              jsonData['message']
                  .toString()
                  .toLowerCase()
                  .contains('no projects')) {
            return [];
          }
        }
        throw Exception(
            'Invalid response format: expected array but got ${jsonData.runtimeType}');
      }

      final List<dynamic> jsonList = jsonData;
      return jsonList
          .map((item) => ProjectResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      // Обрабатываем статусы, когда проектов нет
      if (response.statusCode == 404 || response.statusCode == 204) {
        return [];
      }
      throw Exception('Failed to load projects: ${response.statusCode}');
    }
  }

  Future<List<ProjectResponse>> getMyProjects() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/project/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ProjectResponse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load my projects: ${response.statusCode}');
    }
  }

  Future<void> createProject(String name) async {
    final token = await TokenStorage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/project'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'name': name}),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create project: ${response.statusCode}');
    }
  }

  Future<void> deleteProject(int projectId) async {
    final token = await TokenStorage.getToken();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/v1/project/$projectId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete project: ${response.statusCode}');
    }
  }
}
