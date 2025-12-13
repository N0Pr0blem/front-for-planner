import 'package:it_planner/dto/task/task_detail_response.dart';
import 'package:flutter/material.dart';
import '../dto/task/task_response.dart';
import '../theme/colors.dart';
import 'dart:convert';

class TasksListPanel extends StatefulWidget {
  final int projectId;
  final String? selectedTaskId;
  final Function(TaskResponse) onTaskSelected;
  final VoidCallback onAddTask;
  final List<TaskResponse> tasks;
  final VoidCallback? onTasksUpdated;
  final Function(TaskDetailResponse)? onTaskCreated;
  final bool isMobile;

  const TasksListPanel({
    Key? key,
    required this.projectId,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.onAddTask,
    required this.tasks,
    this.onTasksUpdated,
    this.onTaskCreated,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<TasksListPanel> createState() => _TasksListPanelState();
}

class _TasksListPanelState extends State<TasksListPanel> {
  @override
  void initState() {
    super.initState();
    if (widget.tasks.isEmpty) {
      _loadInitialTasks();
    }
  }

  Future<void> _loadInitialTasks() async {
    try {
      if (widget.onTasksUpdated != null) {
        widget.onTasksUpdated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: $e')),
      );
    }
  }

  Future<void> _refreshTasks() async {
    try {
      if (widget.onTasksUpdated != null) {
        widget.onTasksUpdated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления задач: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTaskSelected =
        widget.selectedTaskId != null && widget.selectedTaskId!.isNotEmpty;

    if (widget.isMobile) {
      return _buildMobileLayout(context, isTaskSelected);
    } else {
      return _buildDesktopLayout(context, isTaskSelected);
    }
  }

  Widget _buildMobileLayout(BuildContext context, bool isTaskSelected) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Задачи (${widget.tasks.length})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add, color: AppColors.primary),
                onPressed: widget.onAddTask,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: widget.tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined, // Исправленная иконка
                          size: 64,
                          color: AppColors.textHint.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет задач',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: widget.onAddTask,
                          child: const Text('Создать первую задачу'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshTasks,
                    child: ListView.builder(
                      itemCount: widget.tasks.length,
                      itemBuilder: (context, index) {
                        final task = widget.tasks[index];
                        return _buildMobileTaskCard(task, context);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, bool isTaskSelected) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Задачи проекта',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                // Если задача выбрана, показываем иконку вместо кнопки
                IconButton(
                  onPressed: widget.onAddTask,
                  icon: Icon(
                    Icons.add,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  tooltip: 'Добавить задачу',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined, // Исправленная иконка
                          size: 64,
                          color: AppColors.textHint.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет задач',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!isTaskSelected)
                          TextButton(
                            onPressed: widget.onAddTask,
                            child: const Text('Создать первую задачу'),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshTasks,
                    child: ListView.builder(
                      itemCount: widget.tasks.length,
                      itemBuilder: (context, index) {
                        final task = widget.tasks[index];
                        final isSelected =
                            widget.selectedTaskId == task.id.toString();
                        return _buildDesktopTaskCard(task, context, isSelected);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTaskCard(TaskResponse task, BuildContext context) {
    final isSelected = widget.selectedTaskId == task.id.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: isSelected ? 2 : 0,
        ),
      ),
      child: ListTile(
        leading: _buildTaskStatusIcon(task.status!),
        title: Text(
          task.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.assignBy.isNotEmpty)
              _buildAssignedMobileView(task)
            else
              const Text(
                'Можно взять в работу',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _getStatusText(task.status!),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(task.status!),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: () => widget.onTaskSelected(task),
      ),
    );
  }

  Widget _buildDesktopTaskCard(
      TaskResponse task, BuildContext context, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.cardBorder.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: isSelected
            ? []
            : const [
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
          onTap: () => widget.onTaskSelected(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTaskStatusIcon(task.status!),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (task.assignBy.isNotEmpty)
                        _buildAssignedDesktopView(task)
                      else
                        const Text(
                          'Можно взять в работу',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Text(
                        _getStatusText(task.status!),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(task.status!),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStatusIcon(String status) {
    IconData icon;
    Color color;

    switch (status.toUpperCase()) {
      case 'TO_DO':
        icon = Icons.radio_button_unchecked;
        color = Colors.blueGrey;
        break;
      case 'IN_PROGRESS':
        icon = Icons.autorenew;
        color = Colors.blue;
        break;
      case 'REVIEW':
        icon = Icons.visibility;
        color = Colors.purple;
        break;
      case 'IN_TEST':
        icon = Icons.bug_report;
        color = Colors.orange;
        break;
      case 'DONE':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      default:
        icon = Icons.help_outline;
        color = Colors.grey;
    }

    return Icon(icon, color: color, size: 24);
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'TO_DO':
        return 'Нужно сделать';
      case 'IN_PROGRESS':
        return 'В работе';
      case 'REVIEW':
        return 'На код ревью';
      case 'IN_TEST':
        return 'В тестировании';
      case 'DONE':
        return 'Готова';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'TO_DO':
        return Colors.blueGrey;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'REVIEW':
        return Colors.purple;
      case 'IN_TEST':
        return Colors.orange;
      case 'DONE':
        return Colors.green;
      default:
        return AppColors.textHint;
    }
  }

  Widget _buildAssignedMobileView(TaskResponse task) {
    return Row(
      children: [
        // Аватарка
        if (task.assignByImage != null && task.assignByImage!.isNotEmpty)
          Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            child: ClipOval(
              child: Image.memory(
                base64Decode(task.assignByImage!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _defaultAvatar(20);
                },
              ),
            ),
          )
        else
          _defaultAvatar(20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.assignBy,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedDesktopView(TaskResponse task) {
    return Row(
      children: [
        // Аватарка
        if (task.assignByImage != null && task.assignByImage!.isNotEmpty)
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            child: ClipOval(
              child: Image.memory(
                base64Decode(task.assignByImage!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _defaultAvatar(24);
                },
              ),
            ),
          )
        else
          _defaultAvatar(24),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.assignBy,
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: AppColors.primary,
      ),
    );
  }
}

// Диалоговое окно подтверждения удаления (оставляем как было)
class _DeleteTaskDialog extends StatefulWidget {
  final TaskResponse task;
  final VoidCallback onDelete;

  const _DeleteTaskDialog({
    Key? key,
    required this.task,
    required this.onDelete,
  }) : super(key: key);

  @override
  _DeleteTaskDialogState createState() => _DeleteTaskDialogState();
}

class _DeleteTaskDialogState extends State<_DeleteTaskDialog>
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
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _deleteTask() async {
    setState(() {
      _isLoading = true;
    });
    try {
      widget.onDelete();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка удаления задачи: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
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
                        'Удалить задачу',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: AppColors.textHint, size: 20),
                        onPressed: _closeDialog,
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Текст подтверждения
                  Text(
                    'Вы уверены, что хотите удалить задачу "${widget.task.name}"?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Это действие нельзя отменить.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
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
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
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
                              onTap: _isLoading ? null : _deleteTask,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
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
                                      : const Text(
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
