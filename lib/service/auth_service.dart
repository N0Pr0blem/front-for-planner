import 'dart:convert';
import 'package:IT_Planner/dto/auth/auth_request.dart';
import 'package:IT_Planner/dto/auth/auth_response.dart';
import 'package:IT_Planner/dto/auth/register_request.dart';
import 'package:IT_Planner/dto/auth/register_response.dart';
import 'package:IT_Planner/dto/auth/verify_request.dart';
import 'package:IT_Planner/dto/auth/verify_response.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.193.60.191:8080';
  
  Future<RegisterResponse> register(RegisterRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/register');
    
    try {
      print('📤 Отправка запроса регистрации на: $url');
      print('📦 Данные: ${request.toJson()}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Получен ответ: ${response.statusCode}');
      print('📄 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return RegisterResponse.fromJson(responseData);
      } else {
        throw Exception('Ошибка регистрации: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Ошибка сети при регистрации: $e');
      throw Exception('Ошибка сети: $e');
    }
  }

  // Существующий метод логина
  Future<AuthResponse> login(AuthRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/login');
    
    try {
      print('📤 Отправка запроса на: $url');
      print('📦 Данные: ${request.toJson()}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      print('📥 Получен ответ: ${response.statusCode}');
      print('📄 Тело ответа: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return AuthResponse.fromJson(responseData);
      } else {
        throw Exception('Ошибка авторизации: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Ошибка сети: $e');
      throw Exception('Ошибка сети: $e');
    }
  }

  Future<VerifyResponse> verifyEmail(VerifyRequest request) async {
  final url = Uri.parse('$baseUrl/api/v1/auth/verify')
      .replace(queryParameters: {
        'username': request.username,
        'code': request.code,
      });

  try {
    print('📤 Отправка запроса верификации на: $url');
    print('📦 Данные: username=${request.username}, code=${request.code}');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print('📥 Получен ответ: ${response.statusCode}');
    print('📄 Тело ответа: ${response.body}');

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Успешная верификация - MessageResponseDto
      return VerifyResponse.fromJson(responseData);
    } else if (response.statusCode == 400) {
      // Ошибка валидации - мапа с error_code
      return VerifyResponse.fromJson(responseData);
    } else {
      // Другие ошибки
      throw Exception('Ошибка верификации: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('💥 Ошибка сети при верификации: $e');
    throw Exception('Ошибка сети: $e');
  }
}
}