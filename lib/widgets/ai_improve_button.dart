import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/ai_service.dart';
import '../theme/colors.dart';

class AIImproveButton extends StatefulWidget {
  final String currentDescription;
  final Function(String) onPreviewGenerated;
  final String taskTitle;

  const AIImproveButton({
    Key? key,
    required this.currentDescription,
    required this.onPreviewGenerated,
    required this.taskTitle,
  }) : super(key: key);

  @override
  State<AIImproveButton> createState() => _AIImproveButtonState();
}

class _AIImproveButtonState extends State<AIImproveButton> {
  bool _isLoading = false;

  Future<void> _generateWithAI() async {
    if (widget.currentDescription.trim().isEmpty) {
      _showSnackBar('Сначала введите описание задачи', Colors.orange);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AIService.improveTaskDescription(
        request: widget.currentDescription,
      );
      
      setState(() {
        _isLoading = false;
      });
      
      widget.onPreviewGenerated(result);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Ошибка: $e', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: IconButton(
        icon: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              )
            : Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 18,
              ),
        onPressed: _isLoading ? null : _generateWithAI,
        tooltip: 'Улучшить с помощью ИИ',
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }
}