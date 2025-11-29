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
}