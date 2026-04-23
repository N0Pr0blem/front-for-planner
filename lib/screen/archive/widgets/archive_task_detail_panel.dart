// lib/screen/archive/widgets/archive_task_detail_panel.dart
import 'package:flutter/material.dart';
import 'package:it_planner/dto/task/task_detail_response.dart';
import 'package:it_planner/service/task_service.dart';
import 'package:it_planner/theme/colors.dart';
import 'package:it_planner/widgets/comments_section.dart';
import 'package:it_planner/widgets/task_documents_section.dart';

class ArchiveTaskDetailPanel extends StatefulWidget {
  final TaskDetailResponse task;
  final VoidCallback onClose;
  final VoidCallback onRestored;
  final bool isMobile;

  const ArchiveTaskDetailPanel({
    Key? key,
    required this.task,
    required this.onClose,
    required this.onRestored,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<ArchiveTaskDetailPanel> createState() => _ArchiveTaskDetailPanelState();
}

class _ArchiveTaskDetailPanelState extends State<ArchiveTaskDetailPanel> {
  String _taskDescription = '';
  bool _isDescriptionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTaskDescription();
  }

  Future<void> _loadTaskDescription() async {
    setState(() {
      _isDescriptionLoading = true;
    });

    try {
      final description = await TaskService.getTaskDescription(widget.task.id);
      setState(() {
        _taskDescription = description;
        _isDescriptionLoading = false;
      });
    } catch (e) {
      setState(() {
        _taskDescription = 'Не удалось загрузить описание';
        _isDescriptionLoading = false;
      });
    }
  }

  Future<void> _restoreTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Восстановить задачу'),
        content: Text('Восстановить задачу "${widget.task.name}" из архива?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Восстановить'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await TaskService.restoreTask(widget.task.id);
        widget.onRestored();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Задача восстановлена из архива'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка восстановления: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Срочно': return Colors.red;
      case 'Средний приоритет': return Colors.orange;
      case 'Не срочно': return Colors.green;
      default: return AppColors.primary;
    }
  }

  Color _getComplexityColor(String complexity) {
    switch (complexity) {
      case 'Большая': return Colors.purple;
      case 'Умеренная': return Colors.blue;
      case 'Небольшая': return Colors.teal;
      default: return AppColors.primary;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'TO_DO': return Colors.blueGrey;
      case 'IN_PROGRESS': return Colors.blue;
      case 'REVIEW': return Colors.purple;
      case 'IN_TEST': return Colors.orange;
      case 'DONE': return Colors.green;
      default: return AppColors.textHint;
    }
  }

  String _getStatusText(String status) {
    switch (status.toUpperCase()) {
      case 'TO_DO': return 'Нужно сделать';
      case 'IN_PROGRESS': return 'В работе';
      case 'REVIEW': return 'На код ревью';
      case 'IN_TEST': return 'В тестировании';
      case 'DONE': return 'Готова';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.unarchive),
            onPressed: _restoreTask,
            tooltip: 'Восстановить из архива',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(widget.task),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    label: 'Приоритет',
                    value: widget.task.priority,
                    color: _getPriorityColor(widget.task.priority),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoCard(
                    label: 'Объем',
                    value: widget.task.complexity,
                    color: _getComplexityColor(widget.task.complexity),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDescriptionSection(),
            const SizedBox(height: 24),
            TaskDocumentsSection(storageId: widget.task.storageId),
            const SizedBox(height: 24),
            CommentsSection(key: ValueKey('comments_${widget.task.id}'), taskId: widget.task.id),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: _restoreTask,
                icon: const Icon(Icons.unarchive),
                label: const Text('Восстановить из архива'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.task.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _restoreTask,
                                icon: const Icon(Icons.unarchive, size: 18),
                                label: const Text('Восстановить'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.textHint, size: 28),
                                onPressed: widget.onClose,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _buildStatusBadge(widget.task),
                              const SizedBox(width: 12),
                              _InfoChip(
                                label: 'Приоритет',
                                value: widget.task.priority,
                                color: _getPriorityColor(widget.task.priority),
                              ),
                              const SizedBox(width: 12),
                              _InfoChip(
                                label: 'Объем',
                                value: widget.task.complexity,
                                color: _getComplexityColor(widget.task.complexity),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _buildDescriptionSection(),
                          const SizedBox(height: 24),
                          TaskDocumentsSection(storageId: widget.task.storageId),
                          const SizedBox(height: 24),
                          CommentsSection(key: ValueKey('comments_${widget.task.id}'), taskId: widget.task.id),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(TaskDetailResponse task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Статус',
            style: TextStyle(fontSize: 12, color: AppColors.textHint),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status!),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getStatusText(task.status!),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: AppColors.textHint)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(TaskDetailResponse task) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(task.status!).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _getStatusColor(task.status!).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _getStatusColor(task.status!),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(task.status!),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _getStatusColor(task.status!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Описание',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
          ),
          child: _isDescriptionLoading
              ? const Center(child: CircularProgressIndicator())
              : _taskDescription.isEmpty
                  ? Text(
                      'Описание отсутствует',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      _taskDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    Key? key,
    required this.label,
    required this.value,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}