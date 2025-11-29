import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/project/project_response.dart';
import '../utils/token_storage.dart';

class ProjectService {
  static const String baseUrl = 'http://localhost:8080';

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
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => ProjectResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
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