import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../dto/repository/repository_file_response.dart';
import '../utils/token_storage.dart';
import 'file_download_service.dart';

class RepositoryService {
  static const String baseUrl = 'http://10.193.60.191:8080';

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
      await FileDownloadService.downloadFile(response.bodyBytes, fileName);
    } else if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  Future<void> uploadFile(int projectId, Uint8List bytes, String fileName) async {
    final token = await TokenStorage.getToken();
    
    if (token == null) {
      throw Exception('No auth token found');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/repository');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    
    Uint8List bytesToUpload = bytes;
    print('[DEBUG Repo] Получены байты. Длина: ${bytes.length}');

    // Создаем multipart file из bytes
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      bytesToUpload,
      filename: fileName,
    );
    
    request.files.add(multipartFile);

    final response = await request.send();
    final responseData = await http.Response.fromStream(response);

    if (response.statusCode != 200 && response.statusCode != 201) {
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
}