import 'dart:convert';
import 'package:it_planner/dto/auth/auth_request.dart';
import 'package:it_planner/dto/auth/auth_response.dart';
import 'package:it_planner/dto/auth/register_request.dart';
import 'package:it_planner/dto/auth/register_response.dart';
import 'package:it_planner/dto/auth/verify_request.dart';
import 'package:it_planner/dto/auth/verify_response.dart';
import 'package:http/http.dart' as http;

class AuthService {
  static const String baseUrl = 'http://10.193.60.191:8080';
  
  Future<RegisterResponse> register(RegisterRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/register');
    
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        return RegisterResponse.fromJson(responseData);
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? response.body;
        throw Exception('$errorMessage');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Ошибка сети: ${e.message}');
      } else {
        rethrow;
      }
    }
  }

 Future<AuthResponse> login(AuthRequest request) async {
  final url = Uri.parse('$baseUrl/api/v1/auth/login');
  
  try {
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);
      return AuthResponse.fromJson(responseData);
    } else {
      try {
        final errorData = jsonDecode(response.body);
        
        String errorMessage = errorData['message'] ?? errorData['error'] ?? response.body;
        
        errorMessage = errorMessage.replaceAll('"', '').trim();
        
        throw Exception(errorMessage);
      } catch (parseError) {
        String errorBody = response.body;
        errorBody = errorBody.replaceAll('"', '').trim();
        throw Exception(errorBody);
      }
    }
  } catch (e) { 
    if (e is http.ClientException) {
      throw Exception('Ошибка сети: ${e.message}');
    } else {
      rethrow;
    }
  }
}

  Future<VerifyResponse> verifyEmail(VerifyRequest request) async {
    final url = Uri.parse('$baseUrl/api/v1/auth/verify')
        .replace(queryParameters: {
          'username': request.username,
          'code': request.code,
        });

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return VerifyResponse.fromJson(responseData);
      } else if (response.statusCode == 400) {
        // Для ошибок валидации также извлекаем сообщение
        final errorMessage = responseData['message'] ?? response.body;
        return VerifyResponse.fromJson(responseData);
      } else {
        final errorMessage = responseData['message'] ?? response.body;
        throw Exception('$errorMessage');
      }
    } catch (e) {
      if (e is http.ClientException) {
        throw Exception('Ошибка сети: ${e.message}');
      } else {
        rethrow;
      }
    }
  }
}