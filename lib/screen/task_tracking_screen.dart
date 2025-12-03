import 'package:flutter/material.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/trekking_response.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
import 'dart:convert';

class TaskTrackingScreen extends StatefulWidget {
  final TaskDetailResponse task;
  final TrekkingResponse? trekking;
  final int projectId;

  const TaskTrackingScreen({
    Key? key,
    required this.task,
    this.trekking,
    required this.projectId,
  }) : super(key: key);

  @override
  State<TaskTrackingScreen> createState() => _TaskTrackingScreenState();
}

class _TaskTrackingScreenState extends State<TaskTrackingScreen> {
  bool _isLoading = false;
  int? _deletingTrekkingId;
  TrekkingResponse? _currentTrekking;

  @override
  void initState() {
    super.initState();
    _currentTrekking = widget.trekking;
  }

  Future<void> _refreshTrekking() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final trekking = await TaskService.getTrekking(widget.task.id);
      setState(() {
        _currentTrekking = trekking;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления трекинга: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showAddTrekkingDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _AddTrekkingDialog(
            task: widget.task,
            onTrekkingAdded: () {
              _refreshTrekking();
              Navigator.pop(context);
            },
            projectId: widget.projectId,
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int trekkingId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Удалить запись времени'),
          content: const Text('Вы уверены, что хотите удалить эту запись времени?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _deleteTrekking(trekkingId);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Удалить'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTrekking(int trekkingId) async {
    setState(() {
      _deletingTrekkingId = trekkingId;
    });

    try {
      await TaskService.deleteTrekking(trekkingId);
      await _refreshTrekking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Запись времени удалена'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _deletingTrekkingId = null;
      });
    }
  }

  String _getEmployeeName(TrekkingEntry entry) {
    final parts = [
      entry.employeeFirstName,
      entry.employeeSecondName,
    ]
        .where((part) => part != null && part.isNotEmpty && part != 'null')
        .toList();

    return parts.isEmpty ? 'Неизвестный сотрудник' : parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final totalHours = _currentTrekking?.hourSum ?? 0.0;
    final trekkingList = _currentTrekking?.trekkingList ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Время и назначения',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(12),
              child: const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refreshTrekking,
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTrekkingDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTrekking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Сводная информация
              _buildSummarySection(totalHours),
              const SizedBox(height: 32),

              // Кто создал и кто назначен
              _buildUsersSection(),
              const SizedBox(height: 32),

              // Детали трекинга
              _buildTrekkingSection(trekkingList),
              const SizedBox(height: 32),

              // Кнопка добавления времени
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddTrekkingDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Добавить время работы'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(double totalHours) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowPrimary,
            offset: Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: AppColors.textOnPrimary,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Общее затраченное время',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalHours.toStringAsFixed(1)} часа',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.name,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textOnPrimary.withOpacity(0.9),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    final assignedBy = widget.task.assignedBy;
    final assignedTo = widget.task.assignedTo;
    final isAssignedToEmpty = assignedTo.firstName.isEmpty ||
        assignedTo.fullName == 'Не назначено';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Назначения',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),

        // Кто создал задачу
        _buildUserCard(
          title: 'Создал задачу',
          user: assignedBy,
          icon: Icons.create,
          color: Colors.blue,
        ),
        const SizedBox(height: 12),

        // Кто назначен на задачу
        _buildUserCard(
          title: 'Ответственный',
          user: assignedTo,
          icon: Icons.person,
          color: isAssignedToEmpty ? Colors.grey : Colors.green,
          isEmpty: isAssignedToEmpty,
        ),
      ],
    );
  }

  Widget _buildUserCard({
    required String title,
    required Assignee user,
    required IconData icon,
    required Color color,
    bool isEmpty = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Иконка
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Текстовая информация
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEmpty ? 'Не назначен' : user.fullName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? AppColors.textHint : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Аватарка если есть
            if (!isEmpty && user.hasAvatar && user.profileImage != null)
              ClipOval(
                child: Image.memory(
                  base64Decode(user.profileImage!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _defaultAvatar(48);
                  },
                ),
              )
            else if (!isEmpty)
              _defaultAvatar(48),
          ],
        ),
      ),
    );
  }

  Widget _buildTrekkingSection(List<TrekkingEntry> trekkingList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'История времени (${trekkingList.length} записей)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (trekkingList.isNotEmpty && !_isLoading)
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: AppColors.primary,
                ),
                onPressed: _refreshTrekking,
              ),
          ],
        ),
        const SizedBox(height: 16),

        if (_isLoading && trekkingList.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.5),
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else if (trekkingList.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cardBorder.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.timer_off,
                  size: 48,
                  color: AppColors.textHint.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'Затраченное время не добавлено',
                  style: TextStyle(
                    color: AppColors.textHint,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Нажмите "Добавить время работы" чтобы начать трекинг',
                  style: TextStyle(
                    color: AppColors.textHint.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          ...trekkingList.map((entry) {
            final isDeleting = _deletingTrekkingId == entry.id;
            return _buildTrekkingEntry(entry, isDeleting);
          }).toList(),
      ],
    );
  }

  Widget _buildTrekkingEntry(TrekkingEntry entry, bool isDeleting) {
    final employeeName = _getEmployeeName(entry);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Иконка времени
            Icon(
              Icons.schedule,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),

            // Информация о трекинге
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${entry.date}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${entry.hours} часа',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textHint,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          employeeName,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Кнопка удаления
            if (!isDeleting)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.textError,
                  size: 20,
                ),
                onPressed: () {
                  _showDeleteConfirmation(entry.id);
                },
              )
            else
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.textError,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}

// Диалог добавления трекинга (упрощенная мобильная версия)
class _AddTrekkingDialog extends StatefulWidget {
  final TaskDetailResponse task;
  final VoidCallback onTrekkingAdded;
  final int projectId;

  const _AddTrekkingDialog({
    Key? key,
    required this.task,
    required this.onTrekkingAdded,
    required this.projectId,
  }) : super(key: key);

  @override
  __AddTrekkingDialogState createState() => __AddTrekkingDialogState();
}

class __AddTrekkingDialogState extends State<_AddTrekkingDialog> {
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
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
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