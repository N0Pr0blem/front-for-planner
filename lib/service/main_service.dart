import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../dto/user/user_response.dart';
import '../utils/token_storage.dart';
import 'package:http_parser/http_parser.dart';

class MainService {
  static const String baseUrl = 'http://10.193.60.191:8080';

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
      throw Exception(
          'Failed to load profile: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> updateProfileWithImage({
    required String secondName,
    required String lastName,
    required Uint8List fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    print('[SERVICE DEBUG] 1. Начало updateProfileWithImage');
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${baseUrl}/api/v1/profile');
    print('[SERVICE DEBUG] 2. URL: $url');
    print('[SERVICE DEBUG] 3. Размер файла для отправки: ${fileBytes.length} байт');

    var request = http.MultipartRequest('PATCH', url);
    
    // Добавляем текстовые поля
    request.fields['secondName'] = secondName;
    request.fields['lastName'] = lastName;
    
    // Добавляем файл
    print('[SERVICE DEBUG] 4. Создание MultipartFile...');
    request.files.add(http.MultipartFile.fromBytes(
      'file',
      fileBytes,
      filename: fileName,
      contentType: _getMediaType(mimeType),
    ));
    
    // Добавляем заголовок авторизации
    request.headers['Authorization'] = 'Bearer $token';
    print('[SERVICE DEBUG] 5. Заголовки запроса: ${request.headers}');

    print('[SERVICE DEBUG] 6. Отправка запроса...');
    try {
      final response = await request.send();
      print('[SERVICE DEBUG] 7. Получен ответ, статус: ${response.statusCode}');
      
      final responseBody = await response.stream.bytesToString();
      print('[SERVICE DEBUG] 8. Тело ответа: $responseBody');
      
      if (response.statusCode == 200) {
        print('[SERVICE DEBUG] 9. УСПЕХ: Профиль обновлен');
        return;
      } else {
        print('[SERVICE DEBUG] 10. ОШИБКА СЕРВЕРА: ${response.statusCode}');
        throw Exception('Failed to update profile: ${response.statusCode} - $responseBody');
      }
    } on SocketException catch (e) {
      print('[SERVICE DEBUG] СЕТЕВАЯ ОШИБКА: $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('[SERVICE DEBUG] HTTP КЛИЕНТ ОШИБКА: $e');
      rethrow;
    } catch (e, stackTrace) {
      print('[SERVICE DEBUG] НЕИЗВЕСТНАЯ ОШИБКА: $e');
      print('[SERVICE DEBUG] СТЭКТРЕЙС: $stackTrace');
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String secondName,
    required String lastName,
  }) async {
    final token = await TokenStorage.getToken();
    final url = Uri.parse('${baseUrl}/api/v1/profile');
    
    var request = http.MultipartRequest('PATCH', url);
    
    // Добавляем только текстовые поля
    request.fields['secondName'] = secondName;
    request.fields['lastName'] = lastName;
    
    // Добавляем заголовок авторизации
    request.headers['Authorization'] = 'Bearer $token';
    
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    
    if (response.statusCode == 200) {
      return; // Успешно
    } else {
      throw Exception('Failed to update profile: ${response.statusCode} - $responseBody');
    }
  }

  MediaType? _getMediaType(String mimeType) {
    switch (mimeType.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return MediaType('image', 'jpeg');
      case 'png':
        return MediaType('image', 'png');
      case 'gif':
        return MediaType('image', 'gif');
      case 'bmp':
        return MediaType('image', 'bmp');
      default:
        return MediaType('image', 'jpeg');
    }
  }
}