import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../dto/task/task_response.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/trekking_response.dart';
import '../dto/task/task_update_request.dart';
import '../dto/task/task_create_request.dart';
import '../utils/token_storage.dart';
import '../dto/task/task_file_response.dart';
import 'dart:html' as html; // Добавляем этот импорт для веб-версии

class TaskService {
  static const String baseUrl = 'http://10.193.60.191:8080';

  static Future<List<TaskResponse>> getTasks(int projectId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/browse');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map((item) => TaskResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load tasks: ${response.statusCode}');
    }
  }

  static Future<TaskDetailResponse> getTaskDetails(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('No auth token');

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return TaskDetailResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load task details: ${response.statusCode}');
    }
  }

  static Future<TrekkingResponse> getTrekking(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) throw Exception('No auth token');

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/trekking');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return TrekkingResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load trekking: ${response.statusCode}');
    }
  }

  static Future<void> updateTaskStatus(int taskId, String newStatus) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');

    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': newStatus,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task status: ${response.statusCode}');
    }
  }

  // В класс TaskService добавьте:
  static Future<void> deleteTrekking(int trekkingId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/trekking/$trekkingId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete trekking: ${response.statusCode}');
    }
  }

  static Future<void> addTrekking({
    required String date,
    required double hours,
    required int projectId,
    required int taskId,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/trekking');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'date': date,
        'hours': hours,
        'project_id': projectId,
        'task_id': taskId,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add trekking: ${response.statusCode}');
    }
  }

  static Future<void> assignTaskToMe({
    required int projectId,
    required int taskId,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/project/$projectId/task/$taskId');

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to assign task: ${response.statusCode}');
    }
  }

  static Future<String> getTaskDescription(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/description');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['message'] as String? ?? '';
    } else {
      throw Exception(
          'Failed to load task description: ${response.statusCode}');
    }
  }

  static Future<void> updateTask({
    required int taskId,
    required TaskUpdateRequest updateRequest,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');
    final response = await http.patch(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(updateRequest.toJson()),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.statusCode}');
    }
  }

  static Future<TaskDetailResponse> createTask({
    required TaskCreateRequest createRequest,
  }) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task');
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(createRequest.toJson()),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return TaskDetailResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create task: ${response.statusCode}');
    }
  }

  static Future<List<TaskResponse>> getMyTasks() async {
    final token = await TokenStorage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/api/v1/task/my'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => TaskResponse.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load my tasks: ${response.statusCode}');
    }
  }

  static Future<List<TaskFileResponse>> getTaskFiles(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/file');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList
          .map(
              (item) => TaskFileResponse.fromJson(item as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load task files: ${response.statusCode}');
    }
  }

  static Future<void> downloadTaskFile(
      int taskId, int fileId, String fileName) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/file/$fileId');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      await _saveTaskFile(response.bodyBytes, fileName);
    } else {
      throw Exception('Failed to download task file: ${response.statusCode}');
    }
  }

  static Future<void> uploadTaskFile(
      int taskId, Uint8List bytes, String fileName) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/file');

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

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to upload task file: ${response.statusCode}');
    }
  }


  static Future<void> _saveTaskFile(List<int> bytes, String fileName) async {
    if (_isWeb()) {
      _downloadForWeb(bytes, fileName);
    } else {
      await _saveFileMobile(bytes, fileName);
    }
  }

  static Future<void> _saveFileMobile(List<int> bytes, String fileName) async {
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
      
      print('Task file saved: ${file.path}');
      
      // Можно добавить уведомление о сохранении
      // Например, через SnackBar в UI
      
    } catch (e) {
      print('Error saving task file: $e');
      rethrow;
    }
  }

  static Future<Directory> _getDownloadDirectory() async {
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

  static bool _isWeb() {
    return identical(0, 0.0);
  }

  static void _downloadForWeb(List<int> bytes, String fileName) {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  static Future<void> deleteTaskFile(int taskId, int fileId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId/file/$fileId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task file: ${response.statusCode}');
    }
  }

  static Future<void> deleteTask(int taskId) async {
    final token = await TokenStorage.getToken();
    if (token == null) {
      throw Exception('No auth token');
    }

    final url = Uri.parse('$baseUrl/api/v1/task/$taskId');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.statusCode}');
    }
  }
}
