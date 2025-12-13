import 'package:it_planner/screen/task_tracking_screen.dart';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/trekking_response.dart';
import '../widgets/task_documents_section.dart';

class TaskDetailPanel extends StatefulWidget {
  final TaskDetailResponse? task;
  final TrekkingResponse? trekking;
  final Function(TaskDetailResponse) onTaskUpdated;
  final VoidCallback onClose;
  final VoidCallback? onTrekkingUpdated;
  final int projectId;
  final VoidCallback? onEdit;
  final bool isMobile;

  const TaskDetailPanel({
    Key? key,
    required this.task,
    this.onEdit,
    required this.onTaskUpdated,
    required this.onClose,
    this.onTrekkingUpdated,
    this.trekking,
    required this.projectId,
    this.isMobile = false,
  }) : super(key: key);

  @override
  State<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel> {
  String _taskDescription = '';
  bool _isDescriptionLoading = false;

  @override
  void initState() {
    super.initState();

    // Загружаем данные при инициализации
    if (widget.task != null) {
      _loadTaskData();
    }
  }

  Future<void> _loadTaskData() async {
    await Future.wait([
      _loadTaskDescription(),
    ]);
  }

  @override
  void didUpdateWidget(TaskDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.task != oldWidget.task && widget.task != null) {
      // Перезагружаем данные при изменении задачи
      _loadTaskData();
    }
  }

  Future<void> _loadTaskDescription() async {
    if (widget.task == null) return;

    setState(() {
      _isDescriptionLoading = true;
    });

    try {
      final description = await TaskService.getTaskDescription(widget.task!.id);
      setState(() {
        _taskDescription = description;
        _isDescriptionLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки описания: $e');
      setState(() {
        _taskDescription = 'Не удалось загрузить описание';
        _isDescriptionLoading = false;
      });
    }
  }

  void _navigateToTrackingScreen(BuildContext context) {
    if (widget.task != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TaskTrackingScreen(
            task: widget.task!,
            trekking: widget.trekking,
            projectId: widget.projectId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task == null) {
      return Container(color: Colors.white);
    }
    final task = widget.task!;

    if (widget.isMobile) {
      return _buildMobileLayout(context, task);
    } else {
      return _buildDesktopLayout(context, task);
    }
  }

  Widget _buildMobileLayout(BuildContext context, TaskDetailResponse task) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMobileStatusCard(task),
          const SizedBox(height: 16),

          // Приоритет и объем — в одну строку
          Row(
            children: [
              Expanded(
                child: _buildMobileInfoCard(
                  label: 'Приоритет',
                  value: task.priority,
                  color: _getPriorityColor(task.priority),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMobileInfoCard(
                  label: 'Объем',
                  value: task.complexity,
                  color: _getComplexityColor(task.complexity),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Ссылка на время и назначения
          _buildTrackingInfoButton(context, widget.trekking?.hourSum ?? 0.0,
              widget.trekking?.trekkingList.length ?? 0),
          const SizedBox(height: 24),

          // Описание — с прокруткой
          _MobileDescriptionSection(
            description: _taskDescription,
            isLoading: _isDescriptionLoading,
            onRefresh: _loadTaskDescription,
          ),
          const SizedBox(height: 24),

          // Документы
          TaskDocumentsSection(taskId: task.id),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMobileStatusCard(TaskDetailResponse task) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Статус',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.edit, color: AppColors.primary),
            onPressed: () {
              _showStatusChangeDialog(context, task);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInfoCard({
    required String label,
    required String value,
    required Color color,
  }) {
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
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingInfoButton(
      BuildContext context, double totalHours, int trekkingCount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToTrackingScreen(context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.timer,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Время и назначения',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${totalHours.toStringAsFixed(1)}h всего • $trekkingCount записей',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textHint,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Нажмите для подробностей',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStatusChangeDialog(BuildContext context, TaskDetailResponse task) {
    final statuses = [
      _StatusItem('TO_DO', 'Нужно сделать', Colors.blueGrey),
      _StatusItem('IN_PROGRESS', 'В работе', Colors.blue),
      _StatusItem('REVIEW', 'На код ревью', Colors.purple),
      _StatusItem('IN_TEST', 'В тестировании', Colors.orange),
      _StatusItem('DONE', 'Готова', Colors.green),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Изменить статус',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: statuses.length,
                itemBuilder: (context, index) {
                  final status = statuses[index];
                  final isSelected = status.value == task.status;
                  return ListTile(
                    leading: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      status.label,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        await TaskService.updateTaskStatus(
                            task.id, status.value);
                        final updatedTask = TaskDetailResponse(
                          id: task.id,
                          name: task.name,
                          isCompleted: task.isCompleted,
                          status: status.value,
                          priority: task.priority,
                          complexity: task.complexity,
                          description: task.description,
                          documents: task.documents,
                          creationDate: task.creationDate,
                          assignedBy: task.assignedBy,
                          assignedTo: task.assignedTo,
                          projectId: task.projectId,
                        );
                        widget.onTaskUpdated(updatedTask);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка обновления статуса: $e'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopLayout(BuildContext context, TaskDetailResponse task) {
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
                      padding:
                          const EdgeInsets.only(top: 24, left: 24, right: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.textHint,
                              size: 28,
                            ),
                            onPressed: widget.onClose,
                            splashRadius: 24,
                            padding: EdgeInsets.zero,
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
                              _ActionButton(
                                icon: Icons.edit,
                                label: 'Редактировать',
                                onTap: widget.onEdit ?? () {},
                              ),
                              const SizedBox(width: 12),
                              _TrackTimeButton(
                                onTap: () {
                                  _showDesktopTrekkingDialog(context, task);
                                },
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _StatusComboBox(
                                  currentStatus: task.status!,
                                  onStatusChanged: (newStatus) async {
                                    try {
                                      await TaskService.updateTaskStatus(
                                          task.id, newStatus);
                                      final updatedTask = TaskDetailResponse(
                                        id: task.id,
                                        name: task.name,
                                        isCompleted: task.isCompleted,
                                        status: newStatus,
                                        priority: task.priority,
                                        complexity: task.complexity,
                                        description: task.description,
                                        documents: task.documents,
                                        creationDate: task.creationDate,
                                        assignedBy: task.assignedBy,
                                        assignedTo: task.assignedTo,
                                        projectId: task.projectId,
                                      );
                                      widget.onTaskUpdated(updatedTask);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                'Ошибка обновления статуса: $e')),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              _InfoChip(
                                label: 'Приоритет',
                                value: task.priority,
                                color: _getPriorityColor(task.priority),
                              ),
                              const SizedBox(width: 12),
                              _InfoChip(
                                label: 'Объем',
                                value: task.complexity,
                                color: _getComplexityColor(task.complexity),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          _DescriptionSection(
                            description: _taskDescription,
                            isLoading: _isDescriptionLoading,
                            onRefresh: _loadTaskDescription,
                          ),
                          const SizedBox(height: 24),
                          TaskDocumentsSection(taskId: task.id),
                          if (widget.trekking != null &&
                              widget.trekking!.trekkingList.isNotEmpty)
                            _TrekkingSection(
                              trekking: widget.trekking!,
                              onTrekkingUpdated: () {
                                if (widget.onTrekkingUpdated != null) {
                                  widget.onTrekkingUpdated!();
                                }
                              },
                            ),
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

  void _showDesktopTrekkingDialog(
      BuildContext context, TaskDetailResponse task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DesktopAddTrekkingDialog(
          task: task,
          onTrekkingAdded: () {
            if (widget.onTrekkingUpdated != null) {
              widget.onTrekkingUpdated!();
            }
          },
          projectId: widget.projectId,
        );
      },
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Срочно':
        return Colors.red;
      case 'Средний приоритет':
        return Colors.orange;
      case 'Не срочно':
        return Colors.green;
      default:
        return AppColors.primary;
    }
  }

  Color _getComplexityColor(String complexity) {
    switch (complexity) {
      case 'Большая':
        return Colors.purple;
      case 'Умеренная':
        return Colors.blue;
      case 'Небольшая':
        return Colors.teal;
      default:
        return AppColors.primary;
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
}

// Мобильная версия диалога добавления времени
class _MobileAddTrekkingDialog extends StatefulWidget {
  final TaskDetailResponse task;
  final VoidCallback onTrekkingAdded;
  final int projectId;

  const _MobileAddTrekkingDialog({
    Key? key,
    required this.task,
    required this.onTrekkingAdded,
    required this.projectId,
  }) : super(key: key);

  @override
  _MobileAddTrekkingDialogState createState() =>
      _MobileAddTrekkingDialogState();
}

class _MobileAddTrekkingDialogState extends State<_MobileAddTrekkingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTrekking() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await TaskService.addTrekking(
          date: _selectedDate.toIso8601String().split('T')[0],
          hours: double.parse(_hoursController.text),
          projectId: widget.projectId,
          taskId: widget.task.id,
        );

        widget.onTrekkingAdded();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Время успешно добавлено'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка добавления времени: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Добавить время работы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Дата
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дата работы',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}.'
                                '${_selectedDate.month.toString().padLeft(2, '0')}.'
                                '${_selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Часы
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Количество часов',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hoursController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите количество часов';
                        }
                        final hours = double.tryParse(value);
                        if (hours == null || hours <= 0) {
                          return 'Введите корректное число часов';
                        }
                        if (hours > 24) {
                          return 'Не более 24 часов в сутки';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTrekking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                            : const Text('Добавить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Мобильная версия секции описания
class _MobileDescriptionSection extends StatelessWidget {
  final String description;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _MobileDescriptionSection({
    Key? key,
    required this.description,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Описание',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRefresh,
                tooltip: 'Обновить описание',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder.withOpacity(0.5),
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : description.isEmpty
                  ? Text(
                      'Описание отсутствует',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : Text(
                      description,
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

// ВЕБ-ВЕРСИЯ: Оставляем все старые классы для десктопа
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    Key? key,
    required this.icon,
    required this.label,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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

class _StatusComboBox extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onStatusChanged;

  const _StatusComboBox({
    required this.currentStatus,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = [
      _StatusItem('TO_DO', 'Нужно сделать', Colors.blueGrey),
      _StatusItem('IN_PROGRESS', 'В работе', Colors.blue),
      _StatusItem('REVIEW', 'На код ревью', Colors.purple),
      _StatusItem('IN_TEST', 'В тестировании', Colors.orange),
      _StatusItem('DONE', 'Готова', Colors.green),
    ];

    final currentStatusItem = statuses.firstWhere(
      (status) => status.value == currentStatus,
      orElse: () => statuses.first,
    );

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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<_StatusItem>(
              value: currentStatusItem,
              isExpanded: true,
              icon: Icon(
                Icons.arrow_drop_down,
                color: AppColors.textHint,
              ),
              items: statuses.map((status) {
                return DropdownMenuItem<_StatusItem>(
                  value: status,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        status.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newStatus) {
                if (newStatus != null) {
                  onStatusChanged(newStatus.value);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusItem {
  final String value;
  final String label;
  final Color color;

  _StatusItem(this.value, this.label, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _StatusItem &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
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
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ВЕБ-ВЕРСИЯ: Оставляем трекинг секцию для десктопа
class _TrekkingSection extends StatefulWidget {
  final TrekkingResponse trekking;
  final Function onTrekkingUpdated;

  const _TrekkingSection({
    Key? key,
    required this.trekking,
    required this.onTrekkingUpdated,
  }) : super(key: key);

  @override
  _TrekkingSectionState createState() => _TrekkingSectionState();
}

class _TrekkingSectionState extends State<_TrekkingSection> {
  int? _deletingTrekkingId;

  Future<void> _deleteTrekking(int trekkingId) async {
    setState(() {
      _deletingTrekkingId = trekkingId;
    });

    try {
      await TaskService.deleteTrekking(trekkingId);
      widget.onTrekkingUpdated();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка удаления трекинга: $e')),
      );
    } finally {
      setState(() {
        _deletingTrekkingId = null;
      });
    }
  }

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Time Tracking',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...widget.trekking.trekkingList.map((entry) {
          final employeeName = _getEmployeeName(entry);
          return Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.5),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.schedule, color: AppColors.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.date}: ${entry.hours}h - $employeeName',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _DeleteTrekkingButton(
                  onDelete: () => _deleteTrekking(entry.id),
                  isLoading: _deletingTrekkingId == entry.id,
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  String _getEmployeeName(TrekkingEntry entry) {
    final parts = [
      entry.employeeFirstName,
      entry.employeeSecondName,
    ]
        .where((part) => part.isNotEmpty && part != 'null')
        .toList();

    return parts.isEmpty ? 'Неизвестный сотрудник' : parts.join(' ');
  }
}

// ... остальные классы (_DeleteTrekkingButton, _TrackTimeButton, _AddTrekkingDialog, _DescriptionSection)
// остаются без изменений для веб-версии

class _TrackTimeButton extends StatelessWidget {
  final VoidCallback onTap;

  const _TrackTimeButton({
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Затрекать время',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
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

class _DeleteTrekkingButton extends StatefulWidget {
  final VoidCallback onDelete;
  final bool isLoading;

  const _DeleteTrekkingButton({
    Key? key,
    required this.onDelete,
    this.isLoading = false,
  }) : super(key: key);

  @override
  __DeleteTrekkingButtonState createState() => __DeleteTrekkingButtonState();
}

class __DeleteTrekkingButtonState extends State<_DeleteTrekkingButton>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isInteractive = !widget.isLoading;

    return MouseRegion(
      onEnter: (_) => isInteractive ? setState(() => _isHovered = true) : null,
      onExit: (_) => isInteractive ? setState(() => _isHovered = false) : null,
      child: GestureDetector(
        onTapDown: (_) =>
            isInteractive ? setState(() => _isPressed = true) : null,
        onTapUp: (_) =>
            isInteractive ? setState(() => _isPressed = false) : null,
        onTapCancel: () =>
            isInteractive ? setState(() => _isPressed = false) : null,
        onTap: isInteractive ? widget.onDelete : null,
        child: Stack(
          children: [
            // Основная кнопка
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isHovered ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: _isHovered
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 0,
                        ),
                      ]
                    : [],
              ),
              transform: _isPressed
                  ? Matrix4.diagonal3Values(0.98, 0.98, 1)
                  : Matrix4.identity(),
              child: Center(
                child: CustomPaint(
                  size: const Size(20,
                      24), // ~44% от 40px ≈ 18px, но чуть больше для читаемости
                  painter: _TrashIconPainter(
                    color: _isHovered ? Colors.white : const Color(0xFFB5BAC1),
                  ),
                ),
              ),
            ),
            // Tooltip
            if (_isHovered)
              Positioned(
                top: -40,
                left: -20,
                right: -20,
                child: AnimatedOpacity(
                  opacity: _isHovered ? 1 : 0,
                  duration: const Duration(milliseconds: 500),
                  child: const _Tooltip(text: 'Delete'),
                ),
              ),
            // Overlay при загрузке
            if (widget.isLoading)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TrashIconPainter extends CustomPainter {
  final Color color;

  const _TrashIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Упрощённый силуэт корзины (можно заменить на точный SVG-путь, но для компактности — упрощённый)
    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..lineTo(size.width * 0.9, size.height * 0.2)
      ..lineTo(size.width * 0.85, size.height * 0.9)
      ..lineTo(size.width * 0.15, size.height * 0.9)
      ..close()
      ..moveTo(size.width * 0.35, size.height * 0.3)
      ..lineTo(size.width * 0.35, size.height * 0.8)
      ..lineTo(size.width * 0.45, size.height * 0.8)
      ..lineTo(size.width * 0.45, size.height * 0.3)
      ..close()
      ..moveTo(size.width * 0.55, size.height * 0.3)
      ..lineTo(size.width * 0.55, size.height * 0.8)
      ..lineTo(size.width * 0.65, size.height * 0.8)
      ..lineTo(size.width * 0.65, size.height * 0.3)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tooltip сверху
class _Tooltip extends StatelessWidget {
  final String text;

  const _Tooltip({required this.text});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF292929),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            bottom: -4,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF292929),
              ),
              transform: Matrix4.rotationZ(45 * (3.14159 / 180)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTrekkingDialog extends StatefulWidget {
  final TaskDetailResponse task;
  final VoidCallback onTrekkingAdded;
  final int projectId;
  final bool isMobile;

  const _AddTrekkingDialog({
    Key? key,
    required this.task,
    required this.onTrekkingAdded,
    required this.projectId,
    this.isMobile = false,
  }) : super(key: key);

  @override
  __AddTrekkingDialogState createState() => __AddTrekkingDialogState();
}

class __AddTrekkingDialogState extends State<_AddTrekkingDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Анимация только для десктоп версии диалога
    if (!widget.isMobile) {
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
  }

  @override
  void dispose() {
    if (!widget.isMobile) {
      _animationController.dispose();
    }
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTrekking() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await TaskService.addTrekking(
          date: _selectedDate.toIso8601String().split('T')[0],
          hours: double.parse(_hoursController.text),
          projectId: widget.projectId,
          taskId: widget.task.id,
        );

        if (mounted) {
          Navigator.of(context).pop();
          widget.onTrekkingAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Время успешно добавлено'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка добавления времени: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return _buildMobileDialog(context);
    } else {
      return _buildDesktopDialog(context);
    }
  }

  Widget _buildMobileDialog(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Добавить время работы',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Дата
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дата работы',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectDate(context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cardBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}.'
                                '${_selectedDate.month.toString().padLeft(2, '0')}.'
                                '${_selectedDate.year}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Часы
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Количество часов',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _hoursController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.0',
                        hintStyle: TextStyle(
                          color: AppColors.textHint,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(
                          Icons.access_time,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введите количество часов';
                        }
                        final hours = double.tryParse(value);
                        if (hours == null || hours <= 0) {
                          return 'Введите корректное число часов';
                        }
                        if (hours > 24) {
                          return 'Не более 24 часов в сутки';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Отмена'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitTrekking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
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
                            : const Text('Добавить'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopDialog(BuildContext context) {
    // Старая версия диалога для десктопа
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ... старая версия диалога для десктопа
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ... методы _selectDate, _submitTrekking, _closeDialog остаются
}

class _DescriptionSection extends StatelessWidget {
  final String description;
  final bool isLoading;
  final VoidCallback onRefresh;

  const _DescriptionSection({
    Key? key,
    required this.description,
    required this.isLoading,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Описание',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onRefresh,
                tooltip: 'Обновить описание',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.cardBorder.withOpacity(0.5),
            ),
          ),
          child: isLoading
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : description.isEmpty
                  ? const Text(
                      'Описание отсутствует',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                        fontStyle: FontStyle.italic,
                      ),
                    )
                  : Text(
                      description,
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

class _DesktopAddTrekkingDialog extends StatefulWidget {
  final TaskDetailResponse task;
  final VoidCallback onTrekkingAdded;
  final int projectId;

  const _DesktopAddTrekkingDialog({
    Key? key,
    required this.task,
    required this.onTrekkingAdded,
    required this.projectId,
  }) : super(key: key);

  @override
  _DesktopAddTrekkingDialogState createState() =>
      _DesktopAddTrekkingDialogState();
}

class _DesktopAddTrekkingDialogState extends State<_DesktopAddTrekkingDialog>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _hoursController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
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
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitTrekking() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await TaskService.addTrekking(
          date: _selectedDate.toIso8601String().split('T')[0],
          hours: double.parse(_hoursController.text),
          projectId: widget.projectId,
          taskId: widget.task.id,
        );

        if (mounted) {
          Navigator.of(context).pop();
          widget.onTrekkingAdded();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Время успешно добавлено'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка добавления времени: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Заголовок
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Добавить время работы',
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

                    // Поле выбора даты
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Дата работы',
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
                              onTap: () => _selectDate(context),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_selectedDate.day.toString().padLeft(2, '0')}.'
                                      '${_selectedDate.month.toString().padLeft(2, '0')}.'
                                      '${_selectedDate.year}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.calendar_today,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Поле ввода часов
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Количество часов',
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
                          child: TextFormField(
                            controller: _hoursController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                            ),
                            decoration: InputDecoration(
                              hintText: '0.0',
                              hintStyle: TextStyle(
                                color: AppColors.textHint,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: Icon(
                                Icons.access_time,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Введите количество часов';
                              }
                              final hours = double.tryParse(value);
                              if (hours == null || hours <= 0) {
                                return 'Введите корректное число часов';
                              }
                              if (hours > 24) {
                                return 'Не более 24 часов в сутки';
                              }
                              return null;
                            },
                          ),
                        ),
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
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
                                onTap: _isLoading ? null : _submitTrekking,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
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
                                            'Добавить',
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
      ),
    );
  }
}
