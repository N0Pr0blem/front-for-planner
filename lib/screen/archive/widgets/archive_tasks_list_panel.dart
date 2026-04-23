import 'package:flutter/material.dart';
import 'package:it_planner/dto/task/task_listing_response.dart';
import 'dart:convert';

import 'package:it_planner/dto/task/task_response.dart';
import 'package:it_planner/screen/archive/widgets/archive_empty_state.dart';
import 'package:it_planner/screen/archive/widgets/archive_header.dart';
import 'package:it_planner/screen/archive/widgets/archive_pagination_bar.dart';
import 'package:it_planner/screen/archive/widgets/archive_search_bar.dart';
import 'package:it_planner/screen/archive/widgets/archive_search_result_info.dart';
import 'package:it_planner/screen/archive/widgets/archive_task_card.dart';
import 'package:it_planner/screen/archive/widgets/restore_task_dialog.dart';
import 'package:it_planner/service/task_service.dart';
import 'package:it_planner/theme/colors.dart';

class ArchiveTasksListPanel extends StatefulWidget {
  final int projectId;
  final String? selectedTaskId;
  final Function(TaskResponse) onTaskSelected;
  final int pageSize;
  final bool isMobile; // ← ДОБАВИТЬ

  const ArchiveTasksListPanel({
    Key? key,
    required this.projectId,
    required this.selectedTaskId,
    required this.onTaskSelected,
    this.pageSize = 10,
    this.isMobile = false, // ← ДОБАВИТЬ
  }) : super(key: key);

  @override
  State<ArchiveTasksListPanel> createState() => _ArchiveTasksListPanelState();
}

class _ArchiveTasksListPanelState extends State<ArchiveTasksListPanel> {
  // Данные
  TaskListingResponse? _listingResponse;
  List<TaskResponse> _tasks = [];
  bool _isLoading = true;

  // Поиск и фильтры
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortAscending = true;
  String? _statusFilter;

  // Пагинация
  int _currentPage = 0;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks({int page = 0}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await TaskService.getTasksPaginated(
        projectId: widget.projectId,
        page: page,
        size: widget.pageSize,
        archived: true,
      );

      if (mounted) {
        setState(() {
          _listingResponse = response;
          _tasks = response.tasks;
          _currentPage = page;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки архива: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshTasks() async {
    await _loadTasks(page: _currentPage);
  }

  Future<void> _restoreTask(TaskResponse task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => RestoreTaskDialog(task: task),
    );

    if (confirmed == true) {
      try {
        await TaskService.restoreTask(task.id);
        await _refreshTasks();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Задача "${task.name}" восстановлена'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка восстановления: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<TaskResponse> _getFilteredAndSortedTasks() {
    List<TaskResponse> filtered = List.from(_tasks);

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((task) {
        return task.name.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_statusFilter != null) {
      filtered = filtered.where((task) {
        return task.status?.toUpperCase() == _statusFilter;
      }).toList();
    }

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

  String _getAssigneeText(TaskResponse task) {
    final assignBy = task.assignBy.trim();
    if (assignBy.isEmpty || assignBy == 'null null') {
      return 'Не назначен';
    }
    return assignBy;
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

  Widget _buildTaskStatusIcon(String status, {double size = 20}) {
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

  @override
  Widget build(BuildContext context) {
    final isTaskSelected =
        widget.selectedTaskId != null && widget.selectedTaskId!.isNotEmpty;
    final filteredTasks = _getFilteredAndSortedTasks();
    final isNarrowMode = widget.isMobile || isTaskSelected; // ← ДОБАВИТЬ

    if (isNarrowMode) {
      return _buildNarrowLayout(context, isTaskSelected, filteredTasks);
    } else {
      return _buildWideLayout(context, isTaskSelected, filteredTasks);
    }
  }

  Widget _buildNarrowLayout(
      BuildContext context, bool isTaskSelected, List<TaskResponse> tasks) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Архив (${tasks.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Icon(
                Icons.archive,
                color: Colors.orange,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? ArchiveEmptyState(
                        hasSearch:
                            _searchQuery.isNotEmpty || _statusFilter != null,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshTasks,
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            return _buildNarrowArchiveTaskCard(task, context);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowArchiveTaskCard(TaskResponse task, BuildContext context) {
    final isSelected = widget.selectedTaskId == task.id.toString();
    final assigneeText = _getAssigneeText(task);
    final hasAssignee =
        task.assignBy.isNotEmpty && task.assignBy != 'null null';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected
              ? Colors.orange
              : AppColors.cardBorder.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => widget.onTaskSelected(task),
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
                          color: isSelected
                              ? Colors.orange
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
                            Icon(Icons.person_off,
                                size: 12, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              'Не назначен',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textHint,
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
                if (isSelected)
                  Icon(Icons.check_circle, color: Colors.orange, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  Widget _buildWideLayout(
      BuildContext context, bool isTaskSelected, List<TaskResponse> tasks) {
    // Тот же код что и раньше, но с использованием ArchiveTaskCard
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ArchiveHeader(
            taskCount: _tasks.length,
            totalPages: _listingResponse?.pages ?? 0,
            currentPage: _currentPage,
            onPageChanged: (page) => _loadTasks(page: page),
          ),
          const SizedBox(height: 16),
          ArchiveSearchBar(
            searchController: _searchController,
            searchQuery: _searchQuery,
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            statusFilter: _statusFilter,
            statuses: _statuses,
            onStatusFilterChanged: (value) =>
                setState(() => _statusFilter = value),
            sortBy: _sortBy,
            onSortByChanged: (value) => setState(() => _sortBy = value!),
            sortAscending: _sortAscending,
            onSortDirectionToggle: () =>
                setState(() => _sortAscending = !_sortAscending),
            onReset: () {
              setState(() {
                _statusFilter = null;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          ),
          const SizedBox(height: 12),
          if (_searchQuery.isNotEmpty || _statusFilter != null)
            ArchiveSearchResultInfo(
              filteredCount: tasks.length,
              totalCount: _tasks.length,
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : tasks.isEmpty
                    ? ArchiveEmptyState(
                        hasSearch:
                            _searchQuery.isNotEmpty || _statusFilter != null,
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshTasks,
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final isSelected =
                                widget.selectedTaskId == task.id.toString();
                            return ArchiveTaskCard(
                              task: task,
                              isSelected: isSelected,
                              onTap: () => widget.onTaskSelected(task),
                              onRestore: () => _restoreTask(task),
                              getStatusText: _getStatusText,
                              getStatusColor: _getStatusColor,
                              getAssigneeText: _getAssigneeText,
                              buildStatusIcon: _buildTaskStatusIcon,
                            );
                          },
                        ),
                      ),
          ),
          if (_listingResponse != null && _listingResponse!.pages > 1)
            ArchivePaginationBar(
              currentPage: _currentPage,
              totalPages: _listingResponse!.pages,
              onPageChanged: (page) => _loadTasks(page: page),
            ),
        ],
      ),
    );
  }
}
