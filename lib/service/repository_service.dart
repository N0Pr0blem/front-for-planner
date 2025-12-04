import 'dart:convert';
import 'dart:io';
import 'dart:html' as html; // Для веб-версии
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../dto/repository/repository_file_response.dart';
import '../utils/token_storage.dart';

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
      await _saveFile(response.bodyBytes, fileName);
    } else if (response.statusCode == 401) {
      await TokenStorage.clearToken();
      throw Exception('Unauthorized. Please log in again.');
    } else {
      throw Exception('Failed to download file: ${response.statusCode}');
    }
  }

  Future<void> _saveFile(List<int> bytes, String fileName) async {
    // Для веб-версии
    if (_isWeb()) {
      _downloadForWeb(bytes, fileName);
    } else {
      // Для мобильных платформ
      await _saveFileMobile(bytes, fileName);
    }
  }

  Future<void> _saveFileMobile(List<int> bytes, String fileName) async {
    try {
      // Запрашиваем разрешение на запись в хранилище (для Android)
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          throw Exception('Storage permission denied');
        }
      }

      // Получаем директорию для сохранения файлов
      final directory = await _getDownloadDirectory();
      
      // Создаем файл
      final file = File('${directory.path}/$fileName');
      
      // Записываем байты в файл
      await file.writeAsBytes(bytes);
      
      print('File saved: ${file.path}');
      
    } catch (e) {
      print('Error saving file: $e');
      rethrow;
    }
  }

  Future<Directory> _getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Для Android используем Downloads директорию
      return Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      // Для iOS используем Documents директорию
      return await getApplicationDocumentsDirectory();
    } else {
      // Для других платформ используем временную директорию
      return await getTemporaryDirectory();
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
}