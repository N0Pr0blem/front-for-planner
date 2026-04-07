// service/ai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/token_storage.dart';

class AIService {
  static const String baseUrl = 'http://192.168.0.103:8080';

  static Future<String> improveTaskDescription({
    required String request,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('No auth token');

    final url = Uri.parse('$baseUrl/api/v1/ai');
    
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'pattern': 'IMPROVE_TASK_DESCRIPTION',
        'request': request,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'] as String;
    } else {
      // Парсим ошибку из ответа сервера
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] as String?;
        if (errorMessage != null) {
          throw Exception(errorMessage);
        }
      } catch (e) {
        // Если не удалось распарсить JSON
      }
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }
  }
}