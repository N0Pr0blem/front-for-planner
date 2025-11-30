import 'package:flutter/material.dart';
import '../dto/task/task_response.dart';
import '../dto/task/task_detail_response.dart';
import '../theme/colors.dart';
import 'dart:convert';
import '../service/task_service.dart'; // Добавляем импорт сервиса

class TasksListPanel extends StatefulWidget {
  final int projectId;
  final String? selectedTaskId;
  final Function(TaskResponse) onTaskSelected;
  final VoidCallback onAddTask;
  final List<TaskResponse> tasks;
  final VoidCallback? onTasksUpdated;
  final Function(TaskDetailResponse)? onTaskCreated;

  const TasksListPanel({
    Key? key,
    required this.projectId,
    required this.selectedTaskId,
    required this.onTaskSelected,
    required this.onAddTask,
    required this.tasks,
    this.onTasksUpdated,
    this.onTaskCreated,
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

  // Новый метод для удаления задачи
  Future<void> _deleteTask(TaskResponse task) async {
    try {
      await TaskService.deleteTask(task.id);
      
      // Обновляем список задач
      if (widget.onTasksUpdated != null) {
        widget.onTasksUpdated!();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Задача "${task.name}" удалена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления задачи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Метод для показа диалога удаления
  void _showDeleteDialog(TaskResponse task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DeleteTaskDialog(
          task: task,
          onDelete: () => _deleteTask(task),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTaskSelected = widget.selectedTaskId != null;

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Шапка с кнопкой добавления, поиском и удаления
          Row(
            children: [
              // Кнопка добавления
              Container(
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
                    onTap: () {
                      widget.onAddTask();
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: AppColors.textOnPrimary,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Поле поиска
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textHint,
                        size: 20,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Список задач
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshTasks,
              child: widget.tasks.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет задач',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.tasks.length,
                      itemBuilder: (context, index) {
                        final task = widget.tasks[index];
                        final isSelected = task.id.toString() == widget.selectedTaskId;
                        return _TaskListItem(
                          task: task,
                          isSelected: isSelected,
                          onTap: () => widget.onTaskSelected(task),
                          onDelete: () => _showDeleteDialog(task),
                          showDeleteButton: !isTaskSelected, // Показываем кнопку удаления только когда панель открыта полностью
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskListItem extends StatelessWidget {
  final TaskResponse task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool showDeleteButton;

  const _TaskListItem({
    Key? key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.showDeleteButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
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
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Используем assignedTo из модели TaskResponse
                      if (task.assignByImage != null && task.assignBy.isNotEmpty)
                        _buildAssignedView(task)
                      else
                        const Text(
                          'Можно взять в работу',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textHint,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                // Кнопка удаления (показываем только когда панель открыта полностью)
                if (showDeleteButton)
                  _TaskDeleteButton(
                    onDelete: onDelete,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAssignedView(TaskResponse task) {
    return Row(
      children: [
        // Аватарка из assignedTo
        if (task.assignByImage != null)
          ClipOval(
            child: Image.memory(
              base64Decode(task.assignByImage!),
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _defaultAvatar();
              },
            ),
          )
        else
          _defaultAvatar(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            task.assignBy, // используем fullName
            style: const TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 14,
        color: AppColors.primary,
      ),
    );
  }
}

// Кнопка удаления в списке задач
class _TaskDeleteButton extends StatelessWidget {
  final VoidCallback onDelete;

  const _TaskDeleteButton({
    Key? key,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDelete,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.textError.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.delete_outline,
          color: AppColors.textError,
          size: 16,
        ),
      ),
    );
  }
}

// Кнопка удаления в хедере
class _DeleteTaskButton extends StatelessWidget {
  final VoidCallback onTap;

  const _DeleteTaskButton({
    Key? key,
    required this.onTap,
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
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.textError.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.delete_outline,
              color: AppColors.textError,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

// Диалоговое окно подтверждения удаления
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
                              onTap: _isLoading ? null : _deleteTask,
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
                                            valueColor: AlwaysStoppedAnimation<Color>(
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