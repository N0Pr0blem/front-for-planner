import 'package:flutter/material.dart';
import 'package:it_planner/dto/task/task_response.dart';
import 'package:it_planner/theme/colors.dart';

class RestoreTaskDialog extends StatefulWidget {
  final TaskResponse task;

  const RestoreTaskDialog({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  _RestoreTaskDialogState createState() => _RestoreTaskDialogState();
}

class _RestoreTaskDialogState extends State<RestoreTaskDialog>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.unarchive, color: Colors.orange),
          const SizedBox(width: 12),
          const Text('Восстановить задачу'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Восстановить задачу "${widget.task.name}" из архива?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Задача вернется в основной список задач.',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Отмена', style: TextStyle(color: AppColors.textHint)),
        ),
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
                  setState(() => _isLoading = true);
                  Navigator.pop(context, true);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Восстановить'),
        ),
      ],
    );
  }
}