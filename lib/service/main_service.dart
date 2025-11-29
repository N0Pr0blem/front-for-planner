import 'dart:convert';
import 'package:http/http.dart' as http;
import '../dto/user/user_response.dart';
import '../utils/token_storage.dart';

class MainService {
  static const String baseUrl = 'http://localhost:8080';

  Future<UserResponse> getProfile() async {
    final token = await TokenStorage.getToken();
    
    if (token == null) {
      throw Exception('No auth token found. User is not logged in.');
    }

    final url = Uri.parse('$baseUrl/api/v1/profile');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return UserResponse.fromJson(data);
    } else if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
    }
  }

}