// service/comment_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_storage.dart';
import '../dto/comment/comment_response.dart';

class CommentService {
  static const String baseUrl = 'http://192.168.0.103:8080';

  // Получение всех комментариев задачи
  static Future<List<CommentResponse>> getTaskComments(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/comment');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final dynamic jsonData = jsonDecode(response.body);
      
      if (jsonData == null) {
        return [];
      }
      
      if (jsonData is! List) {
        throw Exception('Invalid response format: expected array but got ${jsonData.runtimeType}');
      }
      
      final List<dynamic> jsonList = jsonData;
      return jsonList
          .map((item) => CommentResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      if (response.statusCode == 404) {
        return [];
      }
      throw Exception('Failed to load comments: ${response.statusCode}');
    }
  }

  // Создание комментария
  static Future<CommentResponse> createComment({
    required int taskId,
    required String text,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/comment');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return CommentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create comment: ${response.statusCode}');
    }
  }

  // Обновление комментария
  static Future<CommentResponse> updateComment({
    required int taskId,
    required int commentId,
    required String text,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/comment/$commentId');
    
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'text': text}),
    );

    if (response.statusCode == 200) {
      return CommentResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update comment: ${response.statusCode}');
    }
  }

  // Удаление комментария
  static Future<void> deleteComment({
    required int taskId,
    required int commentId,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/comment/$commentId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete comment: ${response.statusCode}');
    }
  }
}