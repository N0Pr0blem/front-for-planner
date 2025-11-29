import 'package:flutter/material.dart';
import 'package:your_app_name/dto/task/trekking_response.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
import '../dto/task/task_detail_response.dart';

class TaskDetailPanel extends StatefulWidget {
  final TaskDetailResponse? task;
  final TrekkingResponse? trekking;
  final Function(TaskDetailResponse)
      onTaskUpdated; 
  final VoidCallback onClose;
  final VoidCallback? onTrekkingUpdated;
  final int projectId;
  final VoidCallback? onEdit;

  const TaskDetailPanel(
      {Key? key,
      required this.task,
      this.onEdit,
      required this.onTaskUpdated,
      required this.onClose,
      this.onTrekkingUpdated,
      this.trekking,
      required this.projectId})
      : super(key: key);

  @override
  State<TaskDetailPanel> createState() => _TaskDetailPanelState();
}

class _TaskDetailPanelState extends State<TaskDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _taskDescription = '';
  bool _isDescriptionLoading = false;


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
    if (widget.task != null) {
      _loadTaskDescription();
    }
  }

  @override
  void didUpdateWidget(TaskDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.task != oldWidget.task && widget.task != null) {
      _loadTaskDescription();
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

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showAddTrekkingDialog(BuildContext context, TaskDetailResponse task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddTrekkingDialog(
            task: task,
            onTrekkingAdded: () {
              if (widget.onTrekkingUpdated != null) {
                widget.onTrekkingUpdated!();
              }
            },
            projectId: widget.projectId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.task == null) {
      return Container(color: Colors.white);
    }
    final task = widget.task!;

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
                    // ВЕРХНИЙ БЛОК С КРЕСТИКОМ
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
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textHint,
                                  size: 28,
                                ),
                                onPressed: widget.onClose,
                                splashRadius: 24,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Контент
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Кнопки и статус
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
                                  _showAddTrekkingDialog(context, task);
                                },
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: _StatusComboBox(
                                  currentStatus: task.status,
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
                                          projectId: task.projectId);
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
                            onRefresh:
                                _loadTaskDescription, 
                          ),
                          const SizedBox(height: 24),
                          _DocumentsSection(
                            documents: task.documents,
                            onDocumentsUpdated: (newDocuments) {
                              final updatedTask = TaskDetailResponse(
                                  id: task.id,
                                  name: task.name,
                                  isCompleted: task.isCompleted,
                                  status: task.status,
                                  priority: task.priority,
                                  complexity: task.complexity,
                                  description: task.description,
                                  documents: newDocuments,
                                  creationDate: task.creationDate,
                                  assignedBy: task.assignedBy,
                                  assignedTo: task.assignedTo,
                                  projectId: task.projectId);
                              widget.onTaskUpdated(updatedTask);
                            },
                          ),
                          if (widget.trekking != null &&
                              widget.trekking!.trekkingList.isNotEmpty)
                            _TrekkingSection(
                                trekking: widget.trekking!,
                                onTrekkingUpdated: () {
                                  if (widget.onTrekkingUpdated != null) {
                                    widget
                                        .onTrekkingUpdated!();
                                  }
                                }),
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
}

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
      _StatusItem('TO_DO', 'Нужно сделать', Colors.grey),
      _StatusItem('IN_PROGRESS', 'В работе', Colors.blue),
      _StatusItem('REVIEW', 'На код ревью', Colors.orange),
      _StatusItem(
          'IN_TEST', 'В тестировании', const Color.fromARGB(255, 255, 0, 242)),
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

class _DocumentsSection extends StatefulWidget {
  final List<String> documents;
  final Function(List<String>) onDocumentsUpdated;

  const _DocumentsSection({
    Key? key,
    required this.documents,
    required this.onDocumentsUpdated,
  }) : super(key: key);

  @override
  _DocumentsSectionState createState() => _DocumentsSectionState();
}

class _DocumentsSectionState extends State<_DocumentsSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Прикрепить документ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.documents.isEmpty)
          _EmptyDocumentsState()
        else
          Column(
            children: widget.documents
                .map((doc) => _DocumentItem(
                      name: doc,
                      onDelete: () {
                        final newDocuments = widget.documents;
                        newDocuments.remove(doc);
                        widget.onDocumentsUpdated(newDocuments);
                      },
                    ))
                .toList(),
          ),
        const SizedBox(height: 12),
        _AddDocumentButton(
          onAdd: () {
            final newDoc = 'document_${widget.documents.length + 1}.pdf';
            final newDocuments = widget.documents;
            newDocuments.add(newDoc);
            widget.onDocumentsUpdated(newDocuments);
          },
        ),
      ],
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

class _DocumentItem extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;

  const _DocumentItem({
    Key? key,
    required this.name,
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
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
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

  @override
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
                    '${entry.date}: ${entry.hours}h - ${entry.employeeFirstName} ${entry.employeeSecondName}',
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

class _AddTrekkingDialog extends StatefulWidget {
  final TaskDetailResponse task;
  final VoidCallback onTrekkingAdded;
  final int projectId; // Добавьте projectId

  const _AddTrekkingDialog({
    Key? key,
    required this.task,
    required this.onTrekkingAdded,
    required this.projectId, // Добавьте сюда
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
            constraints: const BoxConstraints(
              maxWidth: 400,
            ),
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
