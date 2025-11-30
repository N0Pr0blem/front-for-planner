import 'package:flutter/material.dart';
import 'package:your_app_name/dto/task/trekking_response.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/task_update_request.dart';
import '../widgets/task_documents_section.dart';

class TaskEditPanel extends StatefulWidget {
  final TaskDetailResponse task;
  final TrekkingResponse? trekking;
  final Function(TaskDetailResponse) onTaskUpdated;
  final VoidCallback onClose;
  final VoidCallback? onTrekkingUpdated;
  final int projectId;
  final VoidCallback onSave;

  const TaskEditPanel({
    Key? key,
    required this.task,
    required this.onTaskUpdated,
    required this.onClose,
    this.onTrekkingUpdated,
    required this.trekking,
    required this.projectId,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TaskEditPanel> createState() => _TaskEditPanelState();
}

class _TaskEditPanelState extends State<TaskEditPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedUrgency = 'Средний приоритет';
  String _selectedComplexity = 'Умеренная';
  String _selectedStatus = 'TO_DO';
  bool _isLoading = false;
  bool _isDescriptionLoading = false; // Добавляем флаг загрузки описания

  // Маппинг значений для бэкенда
  final _urgencyMap = {
    'Срочно': 'URGENT',
    'Средний приоритет': 'MEDIUM',
    'Не срочно': 'NOT_URGENT',
  };

  final _complexityMap = {
    'Большая': 'HARD',
    'Умеренная': 'MEDIUM',
    'Небольшая': 'EASY',
  };

  // Обратный маппинг для получения русских названий из бэкенд-значений
  final _reverseUrgencyMap = {
    'URGENT': 'Срочно',
    'MEDIUM': 'Средний приоритет',
    'NOT_URGENT': 'Не срочно',
  };

  final _reverseComplexityMap = {
    'HARD': 'Большая',
    'MEDIUM': 'Умеренная',
    'EASY': 'Небольшая',
  };

  @override
  void initState() {
    super.initState();

    // Сначала инициализируем все контроллеры с базовыми значениями
    _nameController = TextEditingController(text: widget.task.name);
    _descriptionController =
        TextEditingController(text: widget.task.description);

    // Установка текущих значений из задачи
    _selectedUrgency = _reverseUrgencyMap[widget.task.priority.toUpperCase()] ??
        'Средний приоритет';
    _selectedComplexity =
        _reverseComplexityMap[widget.task.complexity.toUpperCase()] ??
            'Умеренная';
    _selectedStatus = widget.task.status;

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

    // Загружаем актуальное описание задачи асинхронно
    _loadTaskDescription();
  }

  Future<void> _loadTaskDescription() async {
    // Если описание уже есть в задаче, не загружаем заново
    if (widget.task.description.isNotEmpty) {
      return;
    }

    setState(() {
      _isDescriptionLoading = true;
    });

    try {
      final description = await TaskService.getTaskDescription(widget.task.id);
      if (description.isNotEmpty) {
        _descriptionController.text = description;
      }
    } catch (e) {
      print('Ошибка загрузки описания: $e');
      // Игнорируем ошибку, используем текущее описание
    } finally {
      setState(() {
        _isDescriptionLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updateRequest = TaskUpdateRequest(
        name: _nameController.text,
        urgency: _urgencyMap[_selectedUrgency]!,
        complexity: _complexityMap[_selectedComplexity]!,
        status: _selectedStatus,
        description: _descriptionController.text,
      );

      await TaskService.updateTask(
        taskId: widget.task.id,
        updateRequest: updateRequest,
      );

      // Загружаем обновленные данные с сервера
      final updatedTask = await TaskService.getTaskDetails(widget.task.id);

      widget.onTaskUpdated(updatedTask);
      widget.onSave();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Задача "${_nameController.text}" успешно обновлена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления задачи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddTrekkingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _AddTrekkingDialog(
          task: widget.task,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicWidth(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ВЕРХНИЙ БЛОК С КРЕСТИКОМ И КНОПКАМИ
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 24, left: 24, right: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _nameController,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: 'Название задачи',
                                  contentPadding: EdgeInsets.zero,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Введите название задачи';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            Row(
                              children: [
                                _SaveButton(
                                  onTap: _saveChanges,
                                  isLoading: _isLoading,
                                ),
                                const SizedBox(width: 12),
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // КОНТЕНТ
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Кнопки и статус
                            Row(
                              children: [
                                _TrackTimeButton(
                                  onTap: () => _showAddTrekkingDialog(context),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: _StatusComboBox(
                                    currentStatus: _selectedStatus,
                                    onStatusChanged: (newStatus) {
                                      setState(() {
                                        _selectedStatus = newStatus;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Приоритет и сложность
                            Row(
                              children: [
                                Expanded(
                                  child: _UrgencyComboBox(
                                    currentUrgency: _selectedUrgency,
                                    onUrgencyChanged: (newUrgency) {
                                      setState(() {
                                        _selectedUrgency = newUrgency;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _ComplexityComboBox(
                                    currentComplexity: _selectedComplexity,
                                    onComplexityChanged: (newComplexity) {
                                      setState(() {
                                        _selectedComplexity = newComplexity;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Описание
                            _DescriptionEditSection(
                              controller: _descriptionController,
                              isLoading: _isDescriptionLoading,
                            ),
                            const SizedBox(height: 24),

                            // Документы
                            TaskDocumentsSection(taskId: widget.task.id),

                            // Трекинг
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
            ),
          );
        },
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _SaveButton({
    Key? key,
    required this.onTap,
    required this.isLoading,
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
          onTap: isLoading ? null : onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  Icon(
                    Icons.save,
                    size: 16,
                    color: Colors.white,
                  ),
                const SizedBox(width: 6),
                Text(
                  isLoading ? 'Сохранение...' : 'Сохранить',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
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

class _DescriptionEditSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;

  const _DescriptionEditSection({
    Key? key,
    required this.controller,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              : TextFormField(
                  controller: controller,
                  maxLines: 8,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Введите описание задачи...',
                    hintStyle: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
        ),
      ],
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

class _UrgencyComboBox extends StatelessWidget {
  final String currentUrgency;
  final ValueChanged<String> onUrgencyChanged;

  const _UrgencyComboBox({
    required this.currentUrgency,
    required this.onUrgencyChanged,
  });

  @override
  Widget build(BuildContext context) {
    final urgencies = [
      _UrgencyItem('Срочно', Colors.red),
      _UrgencyItem('Средний приоритет', Colors.orange),
      _UrgencyItem('Не срочно', Colors.green),
    ];

    final currentUrgencyItem = urgencies.firstWhere(
      (urgency) => urgency.label == currentUrgency,
      orElse: () => urgencies.first,
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
            child: DropdownButton<_UrgencyItem>(
              value: currentUrgencyItem,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textHint),
              items: urgencies.map((urgency) {
                return DropdownMenuItem<_UrgencyItem>(
                  value: urgency,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: urgency.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        urgency.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newUrgency) {
                if (newUrgency != null) {
                  onUrgencyChanged(newUrgency.label);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _UrgencyItem {
  final String label;
  final Color color;

  _UrgencyItem(this.label, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _UrgencyItem &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}

class _ComplexityComboBox extends StatelessWidget {
  final String currentComplexity;
  final ValueChanged<String> onComplexityChanged;

  const _ComplexityComboBox({
    required this.currentComplexity,
    required this.onComplexityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final complexities = [
      _ComplexityItem('Большая', Colors.purple),
      _ComplexityItem('Умеренная', Colors.blue),
      _ComplexityItem('Небольшая', Colors.teal),
    ];

    final currentComplexityItem = complexities.firstWhere(
      (complexity) => complexity.label == currentComplexity,
      orElse: () => complexities.first,
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
            child: DropdownButton<_ComplexityItem>(
              value: currentComplexityItem,
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.textHint),
              items: complexities.map((complexity) {
                return DropdownMenuItem<_ComplexityItem>(
                  value: complexity,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: complexity.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        complexity.label,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newComplexity) {
                if (newComplexity != null) {
                  onComplexityChanged(newComplexity.label);
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ComplexityItem {
  final String label;
  final Color color;

  _ComplexityItem(this.label, this.color);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _ComplexityItem &&
          runtimeType == other.runtimeType &&
          label == other.label;

  @override
  int get hashCode => label.hashCode;
}

class _TrekkingSection extends StatefulWidget {
  final TrekkingResponse trekking;
  final Function onTrekkingUpdated; // ← Добавьте колбэк для обновления

  const _TrekkingSection({
    Key? key,
    required this.trekking,
    required this.onTrekkingUpdated, // ← Добавьте этот параметр
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
        const SizedBox(height: 12),
        ...widget.trekking.trekkingList.map((entry) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
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

// Простая иконка корзины как единый path (упрощённая)
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
