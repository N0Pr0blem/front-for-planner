// task_create_panel.dart
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/task_create_request.dart';
import '../widgets/task_documents_section.dart';

class TaskCreatePanel extends StatefulWidget {
  final int projectId;
  final Function(TaskDetailResponse) onTaskCreated;
  final VoidCallback onClose;

  const TaskCreatePanel({
    Key? key,
    required this.projectId,
    required this.onTaskCreated,
    required this.onClose,
  }) : super(key: key);

  @override
  State<TaskCreatePanel> createState() => _TaskCreatePanelState();
}

class _TaskCreatePanelState extends State<TaskCreatePanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedUrgency = 'Срочно';
  String _selectedComplexity = 'Умеренная';
  bool _isLoading = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final createRequest = TaskCreateRequest(
        name: _nameController.text,
        urgency: _urgencyMap[_selectedUrgency]!,
        complexity: _complexityMap[_selectedComplexity]!,
        projectId: widget.projectId,
        description: _descriptionController.text,
      );

      final createdTask = await TaskService.createTask(
        createRequest: createRequest,
      );

      widget.onTaskCreated(createdTask);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Задача "${createdTask.name}" успешно создана'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания задачи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                        padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
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
                                  hintText: 'Название новой задачи',
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
                                _CreateButton(
                                  onTap: _createTask,
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

class _CreateButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isLoading;

  const _CreateButton({
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
                    Icons.add,
                    size: 16,
                    color: Colors.white,
                  ),
                const SizedBox(width: 6),
                Text(
                  isLoading ? 'Создание...' : 'Создать',
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

// Используем те же комбобоксы что и в редактировании
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Приоритет',
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
        ),
      ],
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
      other is _UrgencyItem && runtimeType == other.runtimeType && label == other.label;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Объем',
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
        ),
      ],
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
      other is _ComplexityItem && runtimeType == other.runtimeType && label == other.label;

  @override
  int get hashCode => label.hashCode;
}

class _DescriptionEditSection extends StatelessWidget {
  final TextEditingController controller;

  const _DescriptionEditSection({
    Key? key,
    required this.controller,
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
          child: TextFormField(
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Введите описание задачи';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }
}