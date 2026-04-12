// service/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:it_planner/dto/ai/ai_response_history.dart';
import '../dto/ai/ai_request_response.dart';
import '../utils/token_storage.dart';

class AIService {
  static const String baseUrl = 'http://192.168.0.103:8080';

  // Универсальный метод для всех AI запросов
  static Future<AIRequestResponse> sendAIRequest({
    required String request,
    String pattern = 'CUSTOM',
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Не авторизован');

    final url = Uri.parse('$baseUrl/api/v1/ai');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pattern': pattern,
        'request': request,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AIRequestResponse.fromJson(data);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] as String?;
        if (errorMessage != null && errorMessage.isNotEmpty) {
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }

  // Специализированный метод для улучшения описания задачи
  static Future<String> improveTaskDescription({
    required String request,
  }) async {
    final response = await sendAIRequest(
      request: request,
      pattern: 'IMPROVE_TASK_DESCRIPTION',
    );
    return response.response;
  }

  // Метод для сохранения ответа
  static Future<void> saveAIResponse(AIRequestResponse aiResponse) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('Не авторизован');

    final url = Uri.parse('$baseUrl/api/v1/ai/response');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(aiResponse.toJson()),
    );

    if (response.statusCode != 200) {
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] as String?;
        if (errorMessage != null && errorMessage.isNotEmpty) {
          throw Exception(errorMessage);
        }
      } catch (e) {
        if (e is Exception) rethrow;
      }
      throw Exception('Ошибка сохранения: ${response.statusCode}');
    }
  }

  // service/ai_service.dart - добавляем метод
static Future<List<AIResponseHistory>> getAIResponseHistory() async {
  final token = await TokenStorage.getToken();
  if (token == null) throw Exception('Не авторизован');

  final url = Uri.parse('$baseUrl/api/v1/ai/response');
  
  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200) {
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => AIResponseHistory.fromJson(json)).toList();
  } else {
    try {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData['message'] as String?;
      if (errorMessage != null && errorMessage.isNotEmpty) {
        throw Exception(errorMessage);
      }
    } catch (e) {
      if (e is Exception) rethrow;
    }
    throw Exception('Ошибка сервера: ${response.statusCode}');
  }
}
}