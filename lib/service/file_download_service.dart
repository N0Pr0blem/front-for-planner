import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';
import 'package:universal_html/html.dart' as html;

// Для мобильных платформ
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class FileDownloadService {
  /// Универсальный метод скачивания файлов для всех платформ
  static Future<void> downloadFile(
    List<int> bytes, 
    String fileName,
  ) async {
    if (kIsWeb) {
      await _downloadForWeb(bytes, fileName);
    } else {
      await _downloadForMobile(bytes, fileName);
    }
  }

  /// Метод для веб-платформы
  static Future<void> _downloadForWeb(
    List<int> bytes, 
    String fileName,
  ) async {
    try {
      // Создаем Blob из байтов
      final blob = html.Blob([bytes]);
      
      // Создаем URL для Blob
      final url = html.Url.createObjectUrlFromBlob(blob);
      
      // Создаем скрытую ссылку для скачивания
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';
      
      // Добавляем на страницу
      html.document.body?.append(anchor);
      
      // Кликаем по ссылке
      anchor.click();
      
      // Удаляем ссылку
      anchor.remove();
      
      // Освобождаем URL
      html.Url.revokeObjectUrl(url);
      
      print('Файл $fileName успешно скачан (веб)');
    } catch (e) {
      print('Ошибка при скачивании файла (веб): $e');
      rethrow;
    }
  }

  /// Метод для мобильных платформ (Android/iOS)
  static Future<void> _downloadForMobile(
    List<int> bytes, 
    String fileName,
  ) async {
    try {
      Directory? directory;
      
      // Определяем директорию в зависимости от платформы
      if (Platform.isAndroid) {
        // Для Android используем External Storage
        directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadDir = Directory('${directory.path}/Download');
          if (!await downloadDir.exists()) {
            await downloadDir.create(recursive: true);
          }
          directory = downloadDir;
        }
      } else if (Platform.isIOS) {
        // Для iOS используем Documents
        directory = await getApplicationDocumentsDirectory();
      } else {
        // Для других платформ (Linux/Windows/Mac)
        directory = await getDownloadsDirectory();
      }
      
      // Fallback: если directory null, используем Documents
      directory ??= await getApplicationDocumentsDirectory();
      
      // Создаем файл
      final file = File('${directory.path}/$fileName');
      
      // Записываем байты в файл
      await file.writeAsBytes(bytes, flush: true);
      
      // Открываем файл
      final result = await OpenFile.open(file.path);
      
      if (result.type == ResultType.done) {
        print('Файл $fileName успешно сохранён: ${file.path}');
      } else {
        print('Файл сохранён, но не открыт: ${result.message}');
      }
    } catch (e) {
      print('Ошибка при скачивании файла (мобильный): $e');
      rethrow;
    }
  }

  /// Альтернативный метод с запросом разрешений для Android
  static Future<void> downloadFileWithPermissions(
    List<int> bytes,
    String fileName, {
    bool requestPermission = true,
  }) async {
    if (kIsWeb) {
      await _downloadForWeb(bytes, fileName);
      return;
    }
    
    // Для Android может потребоваться разрешение
    if (Platform.isAndroid && requestPermission) {
      final permissionHandler = await _checkStoragePermission();
      if (!permissionHandler) {
        print('Разрешение на доступ к хранилищу не предоставлено');
        return;
      }
    }
    
    await _downloadForMobile(bytes, fileName);
  }

  /// Проверка разрешений для Android
  static Future<bool> _checkStoragePermission() async {
    try {
      
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        status = await Permission.storage.request();
      }
      
      return status.isGranted;
    } catch (e) {
      print('Ошибка при проверке разрешений: $e');
      return true; // Продолжаем без разрешения
    }
  }
}