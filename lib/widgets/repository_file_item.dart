import 'package:flutter/material.dart';
import '../dto/repository/repository_file_response.dart';
import '../theme/colors.dart';

class RepositoryFileItem extends StatelessWidget {
  final RepositoryFileResponse file;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const RepositoryFileItem({
    Key? key,
    required this.file,
    required this.onDownload,
    required this.onDelete,
  }) : super(key: key);

  Color _getFileColor(String extension) {
    switch (extension) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'zip':
      case 'rar':
      case '7z':
        return Colors.orange;
      case 'txt':
        return Colors.grey;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Colors.pink;
      case 'mp3':
      case 'wav':
        return Colors.teal;
      default:
        return AppColors.primary;
    }
  }

  IconData _getFileIcon(String extension) {
    switch (extension) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
      case 'bmp':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'zip':
      case 'rar':
      case '7z':
        return Icons.archive;
      case 'txt':
        return Icons.text_fields;
      case 'mp4':
      case 'avi':
      case 'mov':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      default:
        return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    final extension = file.fileExtension;
    final fileColor = _getFileColor(extension);
    final fileIcon = _getFileIcon(extension);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onDownload,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Иконка файла
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: fileColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: fileColor.withOpacity(0.3)),
                  ),
                  child: Icon(
                    fileIcon,
                    color: fileColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Информация о файле
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${extension.toUpperCase()} файл',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                // Кнопка удаления
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.shadowLight,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: onDelete,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.delete_outline,
                          color: AppColors.textError,
                          size: 18,
                        ),
                      ),
                    ),
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