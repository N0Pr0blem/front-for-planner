import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../theme/colors.dart';
import '../service/repository_service.dart';

class UploadFileDialog extends StatefulWidget {
  final int projectId;
  final VoidCallback onFileUploaded;

  const UploadFileDialog({
    Key? key,
    required this.projectId,
    required this.onFileUploaded,
  }) : super(key: key);

  @override
  _UploadFileDialogState createState() => _UploadFileDialogState();
}

class _UploadFileDialogState extends State<UploadFileDialog>
    with SingleTickerProviderStateMixin {
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        // Для веб-версии используем bytes, для мобильной - path
        if (file.bytes != null || file.path != null) {
          setState(() {
            _selectedFile = file;
          });
        } else {
          throw Exception('Не удалось получить файл');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка выбора файла: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
  if (_selectedFile == null) return;
  
  setState(() {
    _isLoading = true;
  });

  try {
    print('[UPLOAD DEBUG] Начинаем загрузку файла: ${_selectedFile!.name}');
    
    // КЛЮЧЕВОЙ БЛОК: Получаем байты файла
    Uint8List bytesToUpload;
    
    // 1. Проверяем, есть ли байты сразу в памяти (веб и некоторые случаи на мобильных)
    if (_selectedFile!.bytes != null && _selectedFile!.bytes!.isNotEmpty) {
      bytesToUpload = _selectedFile!.bytes!;
      print('[UPLOAD DEBUG] Используем байты из памяти, размер: ${bytesToUpload.length}');
    } 
    // 2. Если байтов нет (Android 14), но есть путь - читаем с диска
    else if (_selectedFile!.path != null) {
      print('[UPLOAD DEBUG] Байтов нет. Читаем файл с диска: ${_selectedFile!.path}');
      try {
        File diskFile = File(_selectedFile!.path!);
        bool exists = await diskFile.exists();
        
        if (exists) {
          bytesToUpload = await diskFile.readAsBytes();
          print('[UPLOAD DEBUG] Файл прочитан с диска, размер: ${bytesToUpload.length} байт');
        } else {
          throw Exception('Файл не найден на диске по указанному пути');
        }
      } catch (e) {
        print('[UPLOAD DEBUG] Ошибка чтения файла с диска: $e');
        rethrow;
      }
    } 
    // 3. Если ничего нет - это ошибка конфигурации
    else {
      throw Exception('Не удалось получить данные файла: нет ни байтов, ни пути к файлу');
    }

    // ВАЖНО: Проверяем, что байты не пустые перед отправкой
    if (bytesToUpload.isEmpty) {
      throw Exception('Файл не содержит данных (0 байт) после чтения');
    }

    // 3. Вызываем сервис с гарантированно непустыми байтами
    print('[UPLOAD DEBUG] Вызываем RepositoryService.uploadFile...');
    await RepositoryService().uploadFile(
      widget.projectId,
      bytesToUpload, // Теперь здесь точно есть данные
      _selectedFile!.name,
    );
    
    print('[UPLOAD DEBUG] Файл успешно отправлен на сервер!');

    if (mounted) {
      Navigator.of(context).pop();
      widget.onFileUploaded();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл "${_selectedFile!.name}" успешно загружен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('[UPLOAD DEBUG] КРИТИЧЕСКАЯ ОШИБКА ЗАГРУЗКИ: $e');
    print('[UPLOAD DEBUG] Тип ошибки: ${e.runtimeType}');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки файла: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _closeDialog() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Загрузить файл',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        onPressed: _closeDialog,
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Выбор файла
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Файл',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadowLight,
                              offset: Offset(0, 2),
                              blurRadius: 8,
                              spreadRadius: -2,
                            ),
                          ],
                        ),
                        child: Material(
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _pickFile,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedFile?.name ?? 'Выберите файл...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: _selectedFile != null
                                            ? AppColors.textPrimary
                                            : AppColors.textHint,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Icon(
                                    Icons.upload_file,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_selectedFile != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Размер: ${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                offset: Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _closeDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Отмена',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _selectedFile != null && !_isLoading
                                  ? _uploadFile
                                  : null,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _selectedFile != null && !_isLoading
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Загрузить',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}