import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
import '../dto/task/task_file_response.dart';

class TaskDocumentsSection extends StatefulWidget {
  final int taskId;

  const TaskDocumentsSection({
    Key? key,
    required this.taskId,
  }) : super(key: key);

  @override
  _TaskDocumentsSectionState createState() => _TaskDocumentsSectionState();
}

class _TaskDocumentsSectionState extends State<TaskDocumentsSection> {
  List<TaskFileResponse> _taskFiles = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTaskFiles();
  }

  @override
  void didUpdateWidget(TaskDocumentsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Если taskId изменился, перезагружаем файлы
    if (oldWidget.taskId != widget.taskId) {
      _loadTaskFiles();
    }
  }

  Future<void> _loadTaskFiles() async {
    if (widget.taskId == 0) return; // Не загружаем для taskId = 0

    setState(() {
      _isLoading = true;
      _taskFiles = []; // Очищаем предыдущие файлы
    });

    try {
      final files = await TaskService.getTaskFiles(widget.taskId);
      setState(() {
        _taskFiles = files;
      });
    } catch (e) {
      print('Ошибка загрузки файлов для задачи ${widget.taskId}: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки файлов: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadFile(TaskFileResponse file) async {
    try {
      await TaskService.downloadTaskFile(widget.taskId, file.id, file.name);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл "${file.name}" скачан'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка скачивания файла: $e')),
      );
    }
  }

  Future<void> _uploadFile() async {
  try {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      print('[TASK UPLOAD] Файл выбран: ${file.name}, путь: ${file.path}, байты: ${file.bytes != null ? "есть" : "нет"}');
      
      Uint8List fileBytes;
      
      // 1. Проверяем байты в памяти (веб, некоторые мобильные случаи)
      if (file.bytes != null && file.bytes!.isNotEmpty) {
        fileBytes = file.bytes!;
        print('[TASK UPLOAD] Используем байты из памяти');
      } 
      // 2. Если байтов нет, но есть путь - читаем с диска (Android 14)
      else if (file.path != null) {
        print('[TASK UPLOAD] Читаем файл с диска: ${file.path}');
        try {
          File diskFile = File(file.path!);
          bool exists = await diskFile.exists();
          
          if (exists) {
            fileBytes = await diskFile.readAsBytes();
            print('[TASK UPLOAD] Файл прочитан, размер: ${fileBytes.length} байт');
          } else {
            throw Exception('Файл не найден на диске');
          }
        } catch (e) {
          print('[TASK UPLOAD] Ошибка чтения файла: $e');
          rethrow;
        }
      } 
      // 3. Если ничего нет - ошибка
      else {
        throw Exception('Не удалось получить данные файла');
      }
      
      // Загружаем
      setState(() {
        _isLoading = true;
      });

      await TaskService.uploadTaskFile(widget.taskId, fileBytes, file.name);
      await _loadTaskFiles(); // Перезагружаем список файлов
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Файл "${file.name}" успешно загрузки'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('[TASK UPLOAD] Ошибка загрузки: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ошибка загрузки файла: $e'),
        backgroundColor: Colors.red,
      ),
    );
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  void _showDeleteDialog(TaskFileResponse file) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DeleteTaskFileDialog(
          taskId: widget.taskId,
          file: file,
          onFileDeleted: _loadTaskFiles,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прикрепленные файлы',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (_isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_taskFiles.isEmpty)
          _EmptyDocumentsState()
        else
          Column(
            children: _taskFiles
                .map((file) => _TaskFileItem(
                      file: file,
                      onDownload: () => _downloadFile(file),
                      onDelete: () => _showDeleteDialog(file),
                    ))
                .toList(),
          ),
        
        const SizedBox(height: 12),
        _AddDocumentButton(onAdd: _uploadFile),
      ],
    );
  }
}

class _TaskFileItem extends StatelessWidget {
  final TaskFileResponse file;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _TaskFileItem({
    Key? key,
    required this.file,
    required this.onDownload,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.insert_drive_file,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: onDownload,
              child: Text(
                file.name,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.download,
              color: AppColors.primary,
              size: 18,
            ),
            onPressed: onDownload,
          ),
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              color: AppColors.textError,
              size: 18,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _EmptyDocumentsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'No documents attached',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddDocumentButton extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddDocumentButton({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onAdd,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Document',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DeleteTaskFileDialog extends StatefulWidget {
  final int taskId;
  final TaskFileResponse file;
  final VoidCallback onFileDeleted;

  const _DeleteTaskFileDialog({
    Key? key,
    required this.taskId,
    required this.file,
    required this.onFileDeleted,
  }) : super(key: key);

  @override
  _DeleteTaskFileDialogState createState() => _DeleteTaskFileDialogState();
}

class _DeleteTaskFileDialogState extends State<_DeleteTaskFileDialog>
    with SingleTickerProviderStateMixin {
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

  Future<void> _deleteFile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await TaskService.deleteTaskFile(widget.taskId, widget.file.id);

      if (mounted) {
        Navigator.of(context).pop();
        widget.onFileDeleted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл "${widget.file.name}" удален'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления файла: $e'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Удалить файл',
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

                  Text(
                    'Вы уверены, что хотите удалить файл "${widget.file.name}"?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 32),

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
                                color: Colors.red.withOpacity(0.3),
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
                              onTap: _isLoading ? null : _deleteFile,
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.red,
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
                                          'Удалить',
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