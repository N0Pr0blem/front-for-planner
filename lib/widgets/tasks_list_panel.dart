import 'package:flutter/material.dart';
import '../dto/task/task_response.dart';
import '../dto/task/task_detail_response.dart';
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



  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Шапка с кнопкой добавления и поиском
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
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
              onRefresh: _refreshTasks, // Только для pull-to-refresh
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

  const _TaskListItem({
    Key? key,
    required this.task,
    required this.isSelected,
    required this.onTap,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color:
                        isSelected ? AppColors.primary : AppColors.textPrimary,
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
