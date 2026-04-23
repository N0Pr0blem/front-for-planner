import 'package:it_planner/dto/task/task_detail_response.dart';
import 'package:flutter/material.dart';
import '../dto/task/task_response.dart';
import '../theme/colors.dart';
import '../service/task_service.dart';
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
  final bool isCreating;

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
    this.isCreating = false,
  }) : super(key: key);

  @override
  State<TasksListPanel> createState() => _TasksListPanelState();
}

class _TasksListPanelState extends State<TasksListPanel> {
  // Фильтры и поиск
  String _searchQuery = '';
  String _sortBy = 'name'; // 'name', 'status', 'assignee'
  bool _sortAscending = true;
  String? _statusFilter; // null = все статусы
  final Set<int> _selectedTaskIds = {};
  bool _isSelectionMode = false;

  final TextEditingController _searchController = TextEditingController();

  // Список статусов для фильтра
  final List<Map<String, dynamic>> _statuses = [
    {'value': null, 'label': 'Все статусы', 'color': Colors.grey},
    {'value': 'TO_DO', 'label': 'Нужно сделать', 'color': Colors.blueGrey},
    {'value': 'IN_PROGRESS', 'label': 'В работе', 'color': Colors.blue},
    {'value': 'REVIEW', 'label': 'На код ревью', 'color': Colors.purple},
    {'value': 'IN_TEST', 'label': 'В тестировании', 'color': Colors.orange},
    {'value': 'DONE', 'label': 'Готова', 'color': Colors.green},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.tasks.isEmpty) {
      _loadInitialTasks();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _archiveTask(TaskResponse task) async {
    await showDialog(
      context: context,
      builder: (context) => _ArchiveTaskDialog(
        task: task,
        onArchive: () async {
          try {
            await TaskService.archiveTask(task.id);
            if (widget.onTasksUpdated != null) {
              widget.onTasksUpdated!();
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Задача "${task.name}" перемещена в архив'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка архивации: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _toggleSelectionMode() {
    setState(() {
      if (_isSelectionMode) {
        _selectedTaskIds.clear();
      }
      _isSelectionMode = !_isSelectionMode;
    });
  }

  void _toggleTaskSelection(TaskResponse task) {
    setState(() {
      if (_selectedTaskIds.contains(task.id)) {
        _selectedTaskIds.remove(task.id);
      } else {
        _selectedTaskIds.add(task.id);
      }
    });
  }

  void _selectAllTasks(List<TaskResponse> tasks) {
    setState(() {
      if (_selectedTaskIds.length == tasks.length) {
        _selectedTaskIds.clear();
      } else {
        _selectedTaskIds.addAll(tasks.map((t) => t.id));
      }
    });
  }

  Future<void> _archiveSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _BulkArchiveDialog(
        count: _selectedTaskIds.length,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      try {
        await TaskService.archiveTasksBulk(_selectedTaskIds.toList());
        _toggleSelectionMode();
        if (widget.onTasksUpdated != null) {
          widget.onTasksUpdated!();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('${_selectedTaskIds.length} задач перемещено в архив'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка архивации: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteSelectedTasks() async {
    if (_selectedTaskIds.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _BulkDeleteDialog(
        count: _selectedTaskIds.length,
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      try {
        await TaskService.deleteTasksBulk(_selectedTaskIds.toList());
        _toggleSelectionMode();
        if (widget.onTasksUpdated != null) {
          widget.onTasksUpdated!();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_selectedTaskIds.length} задач удалено'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка удаления: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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

  Future<void> _deleteTask(TaskResponse task) async {
    await showDialog(
      context: context,
      builder: (context) => _DeleteTaskDialog(
        task: task,
        onDelete: () async {
          try {
            await TaskService.deleteTask(task.id);
            if (widget.onTasksUpdated != null) {
              widget.onTasksUpdated!();
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Задача "${task.name}" удалена'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ошибка удаления: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String _getAssigneeText(TaskResponse task) {
    final assignBy = task.assignBy.trim();
    if (assignBy.isEmpty || assignBy == 'null null') {
      return 'Можно взять в работу';
    }
    return assignBy;
  }

  // Фильтрация и сортировка задач
  List<TaskResponse> _getFilteredAndSortedTasks() {
    List<TaskResponse> filtered = List.from(widget.tasks);

    // Фильтр по поисковому запросу
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Фильтр по статусу
    if (_statusFilter != null) {
      filtered = filtered.where((task) {
        return task.status?.toUpperCase() == _statusFilter;
      }).toList();
    }

    // Сортировка
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'status':
          comparison = (a.status ?? '').compareTo(b.status ?? '');
          break;
        case 'assignee':
          final aAssignee = _getAssigneeText(a);
          final bAssignee = _getAssigneeText(b);
          comparison = aAssignee.compareTo(bAssignee);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isTaskSelected =
        widget.selectedTaskId != null && widget.selectedTaskId!.isNotEmpty;
    final filteredTasks = _getFilteredAndSortedTasks();
    final isNarrowMode = widget.isMobile || isTaskSelected || widget.isCreating;

    if ((isTaskSelected || widget.isCreating) && _isSelectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _toggleSelectionMode();
      });
    }

    if (isNarrowMode) {
      return _buildNarrowLayout(context, isTaskSelected, filteredTasks);
    } else {
      return _buildWideLayout(context, isTaskSelected, filteredTasks);
    }
  }

// В _buildNarrowLayout добавим кнопку "Выбрать" в заголовок:
// Узкий режим (мобилка ИЛИ когда задача выбрана - панель свернута)
  Widget _buildNarrowLayout(
      BuildContext context, bool isTaskSelected, List<TaskResponse> tasks) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с режимом выбора или обычный
          if (_isSelectionMode)
            _buildNarrowSelectionModeHeader(tasks)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Задачи (${tasks.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    // Кнопка выбора
                    TextButton.icon(
                      onPressed: _toggleSelectionMode,
                      icon: Icon(Icons.checklist,
                          size: 16, color: AppColors.primary),
                      label: Text(
                        'Выбрать',
                        style:
                            TextStyle(fontSize: 11, color: AppColors.primary),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        backgroundColor: AppColors.primary.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: Icon(Icons.add, color: AppColors.primary, size: 20),
                      onPressed: widget.onAddTask,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 12),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 48,
                          color: AppColors.textHint.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Ничего не найдено'
                              : 'Нет задач',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_searchQuery.isEmpty && _statusFilter == null)
                          TextButton(
                            onPressed: widget.onAddTask,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                            child: const Text('Создать первую задачу',
                                style: TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshTasks,
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return _buildNarrowTaskCard(
                          task,
                          context,
                          isSelectionMode: _isSelectionMode,
                          isChecked: _selectedTaskIds.contains(task.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

// Заголовок для узкого режима в режиме выбора
  Widget _buildNarrowSelectionModeHeader(List<TaskResponse> tasks) {
    final allSelected =
        _selectedTaskIds.length == tasks.length && tasks.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (_) => _selectAllTasks(tasks),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Выбрать все',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_selectedTaskIds.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _selectedTaskIds.isNotEmpty
                      ? _archiveSelectedTasks
                      : null,
                  icon: const Icon(Icons.archive, size: 16),
                  label: const Text('В архив', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _selectedTaskIds.isNotEmpty ? _deleteSelectedTasks : null,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Удалить', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _toggleSelectionMode,
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Отмена',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

// Обновленная карточка для узкого режима с поддержкой выбора
  Widget _buildNarrowTaskCard(
    TaskResponse task,
    BuildContext context, {
    bool isSelectionMode = false,
    bool isChecked = false,
  }) {
    final isSelected = widget.selectedTaskId == task.id.toString();
    final assigneeText = _getAssigneeText(task);
    final hasAssignee =
        task.assignBy.isNotEmpty && task.assignBy != 'null null';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected && !isSelectionMode
            ? AppColors.primary.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected && !isSelectionMode
              ? AppColors.primary
              : isChecked
                  ? AppColors.primary
                  : AppColors.cardBorder.withOpacity(0.5),
          width: (isSelected && !isSelectionMode) || isChecked ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: isSelectionMode
              ? () => _toggleTaskSelection(task)
              : () => widget.onTaskSelected(task),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                _buildTaskStatusIcon(task.status!, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _truncateText(task.name, 25),
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          color: isSelected && !isSelectionMode
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (hasAssignee) ...[
                            Icon(Icons.person,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                _truncateText(assigneeText, 15),
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          ] else ...[
                            Icon(Icons.person_add_alt_1,
                                size: 12,
                                color: AppColors.primary.withOpacity(0.7)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Можно взять',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.textHint.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getStatusText(task.status!),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: _getStatusColor(task.status!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Чекбокс или галочка справа
                if (isSelectionMode) ...[
                  const SizedBox(width: 8),
                  Checkbox(
                    value: isChecked,
                    onChanged: (_) => _toggleTaskSelection(task),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ] else if (isSelected) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 18),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Широкий режим (когда задача НЕ выбрана - панель широкая)
  Widget _buildWideLayout(
      BuildContext context, bool isTaskSelected, List<TaskResponse> tasks) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Обновленный заголовок с режимом выбора
          if (_isSelectionMode)
            _buildSelectionModeHeader(tasks)
          else
            _buildNormalHeader(),

          const SizedBox(height: 16),

          // Панель поиска и фильтрации (скрываем в режиме выбора)
          if (!_isSelectionMode) ...[
            _buildSearchAndFilterBar(),
            const SizedBox(height: 12),
          ],

          // Результат поиска
          if (!_isSelectionMode &&
              (_searchQuery.isNotEmpty || _statusFilter != null))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Найдено: ${tasks.length} из ${widget.tasks.length}',
                style: TextStyle(fontSize: 11, color: AppColors.textHint),
              ),
            ),

          Expanded(
            child: tasks.isEmpty
                ? _buildEmptyState(isTaskSelected)
                : RefreshIndicator(
                    onRefresh: _refreshTasks,
                    child: ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final isSelected =
                            widget.selectedTaskId == task.id.toString();
                        return _buildWideTaskCard(
                          task,
                          context,
                          isSelected,
                          isSelectionMode: _isSelectionMode,
                          isChecked: _selectedTaskIds.contains(task.id),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // В класс _TasksListPanelState добавьте метод:

  Widget _buildEmptyState(bool isTaskSelected) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _statusFilter != null
                ? 'Ничего не найдено'
                : 'Нет задач',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          if (_searchQuery.isEmpty && _statusFilter == null && !isTaskSelected)
            TextButton(
              onPressed: widget.onAddTask,
              child: const Text('Создать первую задачу'),
            ),
        ],
      ),
    );
  } // Замените метод _buildNormalHeader:

  Widget _buildNormalHeader() {
    return Row(
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
        Row(
          children: [
            // Кнопка для входа в режим выбора
            TextButton.icon(
              onPressed: _toggleSelectionMode,
              icon: Icon(Icons.checklist, size: 18, color: AppColors.primary),
              label: Text(
                'Выбрать',
                style: TextStyle(fontSize: 13, color: AppColors.primary),
              ),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppColors.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Кнопка создания задачи
            IconButton(
              onPressed: widget.onAddTask,
              icon: Icon(Icons.add, color: AppColors.primary, size: 24),
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
      ],
    );
  }
// Замените метод _buildSelectionModeHeader:

  Widget _buildSelectionModeHeader(List<TaskResponse> tasks) {
    final allSelected =
        _selectedTaskIds.length == tasks.length && tasks.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          // Чекбокс "Выбрать все"
          Row(
            children: [
              Checkbox(
                value: allSelected,
                onChanged: (_) => _selectAllTasks(tasks),
                activeColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Text(
                'Выбрать все',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Счетчик выбранных
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_selectedTaskIds.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          // Кнопки действий
          if (_selectedTaskIds.isNotEmpty) ...[
            // Кнопка архивации - более заметная
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _archiveSelectedTasks,
                icon: const Icon(Icons.archive, size: 18),
                label: const Text('В архив'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Кнопка удаления - более заметная
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _deleteSelectedTasks,
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Удалить'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ] else ...[
            // Если ничего не выбрано - показываем неактивные кнопки
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.archive, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'В архив',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Удалить',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(width: 16),
          // Разделитель
          Container(
            width: 1,
            height: 32,
            color: AppColors.cardBorder.withOpacity(0.5),
          ),
          const SizedBox(width: 8),
          // Кнопка отмены
          TextButton(
            onPressed: _toggleSelectionMode,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Отмена',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Поле поиска
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textHint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Поиск',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear,
                                  color: AppColors.textHint, size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchQuery = '';
                                  _searchController.clear();
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),

          // Разделитель
          Container(
            width: 1,
            height: 28,
            color: AppColors.cardBorder.withOpacity(0.5),
          ),

          // Фильтр по статусу
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String?>(
              value: _statusFilter,
              hint: Row(
                children: [
                  Icon(Icons.filter_list, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Статус',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textHint)),
                ],
              ),
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down,
                  size: 20, color: AppColors.textHint),
              items: _statuses.map((status) {
                return DropdownMenuItem<String?>(
                  value: status['value'],
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status['label'],
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _statusFilter = newValue;
                });
              },
            ),
          ),

          // Разделитель
          Container(
            width: 1,
            height: 28,
            color: AppColors.cardBorder.withOpacity(0.5),
          ),

          // Сортировка
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: _sortBy,
              hint: Row(
                children: [
                  Icon(Icons.sort, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Сорт.',
                      style:
                          TextStyle(fontSize: 14, color: AppColors.textHint)),
                ],
              ),
              underline: const SizedBox(),
              icon: Icon(Icons.arrow_drop_down,
                  size: 20, color: AppColors.textHint),
              items: const [
                DropdownMenuItem(
                    value: 'name',
                    child: Text('По названию', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(
                    value: 'status',
                    child: Text('По статусу', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(
                    value: 'assignee',
                    child:
                        Text('По исполнителю', style: TextStyle(fontSize: 13))),
              ],
              onChanged: (newValue) {
                setState(() {
                  _sortBy = newValue!;
                });
              },
            ),
          ),

          // Кнопка направления сортировки
          IconButton(
            onPressed: () {
              setState(() {
                _sortAscending = !_sortAscending;
              });
            },
            icon: Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: AppColors.primary,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: _sortAscending ? 'По возрастанию' : 'По убыванию',
          ),

          // Кнопка сброса (только если есть активные фильтры)
          if (_statusFilter != null || _searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _statusFilter = null;
                    _searchQuery = '';
                    _searchController.clear();
                  });
                },
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Сбросить',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

// Обновленная карточка задачи без кнопок архива и удаления
  Widget _buildWideTaskCard(
    TaskResponse task,
    BuildContext context,
    bool isSelected, {
    bool isSelectionMode = false,
    bool isChecked = false,
  }) {
    final assigneeText = _getAssigneeText(task);
    final hasAssignee =
        task.assignBy.isNotEmpty && task.assignBy != 'null null';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected && !isSelectionMode
            ? AppColors.primary.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected && !isSelectionMode
              ? AppColors.primary
              : isChecked
                  ? AppColors.primary
                  : AppColors.cardBorder.withOpacity(0.5),
          width: (isSelected && !isSelectionMode) || isChecked ? 2 : 1,
        ),
        boxShadow: isSelected && !isSelectionMode
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
          onTap: isSelectionMode
              ? () => _toggleTaskSelection(task)
              : () => widget.onTaskSelected(task),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                _buildTaskStatusIcon(task.status!, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected && !isSelectionMode
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasAssignee) ...[
                            if (task.assignByImage != null &&
                                task.assignByImage!.isNotEmpty)
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(right: 6),
                                child: ClipOval(
                                  child: Image.memory(
                                    base64Decode(task.assignByImage!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person,
                                          size: 18, color: AppColors.textHint);
                                    },
                                  ),
                                ),
                              )
                            else
                              Icon(Icons.person,
                                  size: 16, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              assigneeText,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textHint),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.textHint.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ] else ...[
                            Icon(
                              Icons.person_add_alt_1,
                              size: 16,
                              color: AppColors.primary.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Можно взять в работу',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.primary.withOpacity(0.7),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.textHint.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
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
                    ],
                  ),
                ),
                if (isSelectionMode) ...[
                  const SizedBox(width: 12),
                  Checkbox(
                    value: isChecked,
                    onChanged: (_) => _toggleTaskSelection(task),
                    activeColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ] else if (isSelected) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTaskStatusIcon(String status, {double size = 22}) {
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

    return Icon(icon, color: color, size: size);
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
}

// В файле tasks_list_panel.dart добавьте новый класс диалога:

class _ArchiveTaskDialog extends StatefulWidget {
  final TaskResponse task;
  final VoidCallback onArchive;

  const _ArchiveTaskDialog({
    Key? key,
    required this.task,
    required this.onArchive,
  }) : super(key: key);

  @override
  _ArchiveTaskDialogState createState() => _ArchiveTaskDialogState();
}

class _ArchiveTaskDialogState extends State<_ArchiveTaskDialog>
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

  Future<void> _archiveTask() async {
    setState(() {
      _isLoading = true;
    });
    try {
      widget.onArchive();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
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
        Navigator.of(context).pop(false);
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'В архив',
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
                  Text(
                    'Переместить задачу "${widget.task.name}" в архив?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Задача будет скрыта из основного списка, но её можно будет восстановить.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                  ),
                  const SizedBox(height: 32),
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
                                color: Colors.orange.withOpacity(0.3),
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
                              onTap: _isLoading ? null : _archiveTask,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
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
                                          'В архив',
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
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
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
        Navigator.of(context).pop(false);
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

class _BulkArchiveDialog extends StatelessWidget {
  final int count;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BulkArchiveDialog({
    Key? key,
    required this.count,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.archive, color: Colors.orange),
          const SizedBox(width: 12),
          const Text('Переместить в архив'),
        ],
      ),
      content: Text(
        'Вы уверены, что хотите переместить $count задач в архив?',
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Отмена', style: TextStyle(color: AppColors.textHint)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('В архив'),
        ),
      ],
    );
  }
}

class _BulkDeleteDialog extends StatelessWidget {
  final int count;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _BulkDeleteDialog({
    Key? key,
    required this.count,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.delete, color: Colors.red),
          const SizedBox(width: 12),
          const Text('Удалить задачи'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Вы уверены, что хотите удалить $count задач?',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            'Это действие нельзя отменить.',
            style: TextStyle(fontSize: 14, color: AppColors.textHint),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onCancel,
          child: Text('Отмена', style: TextStyle(color: AppColors.textHint)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Удалить'),
        ),
      ],
    );
  }
}
