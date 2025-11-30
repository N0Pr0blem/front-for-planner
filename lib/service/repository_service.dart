import 'dart:convert';
import 'dart:io';
import 'dart:html' as html; // Добавьте для веб-версии
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../dto/repository/repository_file_response.dart';
import '../utils/token_storage.dart';

class RepositoryService {
  static const String baseUrl = 'http://localhost:8080';

  Future<List<RepositoryFileResponse>> getRepositoryFiles(int projectId) async {
    final token = await TokenStorage.getToken();
    
    if (token == null) {
      throw Exception('No auth token found');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/repository');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => RepositoryFileResponse.fromJson(item)).toList();
    } else if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to load repository files: ${response.statusCode}');
    }
  }

  Future<void> downloadFile(int projectId, int fileId, String fileName) async {
    final token = await TokenStorage.getToken();
    
    if (token == null) {
      throw Exception('No auth token found');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/repository/file/$fileId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      _saveFile(response.bodyBytes, fileName);
    } else if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  void _saveFile(List<int> bytes, String fileName) {
    // Для веб-версии
    if (_isWeb()) {
      _downloadForWeb(bytes, fileName);
    } else {
      // Для мобильной версии
      print('File downloaded: $fileName (${bytes.length} bytes)');
      // TODO: Реализовать сохранение файла для мобильной платформы
    }
  }

  bool _isWeb() {
    return identical(0, 0.0);
  }

  void _downloadForWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  Future<void> uploadFile(int projectId, File file) async {
    final token = await TokenStorage.getToken();
    
    if (token == null) {
      throw Exception('No auth token found');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/repository');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      contentType: MediaType('application', 'octet-stream'),
    ));

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to upload file: ${response.statusCode} - ${responseData.body}');
    }
  }

  Future<void> deleteFile(int projectId, int fileId) async {
    final token = await TokenStorage.getToken();
    
    if (token == null) {
      throw Exception('No auth token found');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/repository/file/$fileId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        await TokenStorage.clearToken();
        throw Exception('Unauthorized. Please log in again.');
      } else {
        throw Exception('Failed to delete file: ${response.statusCode}');
      }
    }
  }

  // Добавьте этот метод в RepositoryService
Future<void> uploadFileBytes(int projectId, List<int> bytes, String fileName) async {
  final token = await TokenStorage.getToken();
  
  if (token == null) {
    throw Exception('No auth token found');
  }

  final url = Uri.parse('$baseUrl/api/v1/project/$projectId/repository');

  var request = http.MultipartRequest('POST', url);
  request.headers['Authorization'] = 'Bearer $token';
  
  // Создаем multipart file из bytes
  final multipartFile = http.MultipartFile.fromBytes(
    'file',
    bytes,
    filename: fileName,
  );
  
  request.files.add(multipartFile);

  final response = await request.send();
  final responseData = await http.Response.fromStream(response);

  if (response.statusCode != 200) {
    throw Exception('Failed to upload file: ${response.statusCode} - ${responseData.body}');
  }
}
}