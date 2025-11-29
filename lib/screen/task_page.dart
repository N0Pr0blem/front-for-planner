import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/tasks_list_panel.dart';
import '../widgets/task_detail_panel.dart';
import '../widgets/task_info_panel.dart';
import '../theme/colors.dart';
import '../dto/project/project_response.dart';
import '../dto/task/task_detail_response.dart';
import '../dto/task/task_response.dart';
import '../dto/task/trekking_response.dart';
import '../service/task_service.dart';
import '../service/project_service.dart';
import '../widgets/task_create_panel.dart';
import '../widgets/task_edit_panel.dart';

class TasksPage extends StatefulWidget {
  const TasksPage({Key? key}) : super(key: key);

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  String? _selectedTaskId;
  bool _isTaskSelected = false;
  ProjectResponse? _selectedProject;
  TaskDetailResponse? _currentTaskDetails;
  TrekkingResponse? _currentTrekking;
  List<TaskResponse> _tasks = [];
  bool _isCreating = false;
  bool _isEditing = false;
  Assignee? _currentUser;

  void _startCreating() {
    setState(() {
      _isCreating = true;
      _isTaskSelected = true;
      _currentTaskDetails = null;
    });
  }

  void _stopCreating() {
    setState(() {
      _isCreating = false;
      _isTaskSelected = false;
    });
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void _stopEditing() {
    setState(() {
      _isEditing = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      setState(() {
        _currentUser = Assignee(
          profileImage: null,
          firstName: 'Текущий', // Замените на реальные данные
          secondName: 'Пользователь',
          lastName: null,
        );
      });
    } catch (e) {
      print('Ошибка загрузки пользователя: $e');
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ProjectService().getProjects();
      if (projects.isEmpty) {
        setState(() {
          _selectedProject = null;
        });
        return;
      }
      final selected = projects[0];
      setState(() {
        _selectedProject = selected;
      });
      _loadTasks(selected.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки проектов: $e')),
      );
    }
  }

  void _onProjectSelected(ProjectResponse project) {
    setState(() {
      _selectedProject = project;
    });
    _loadTasks(project.id);
  }

  Future<void> _refreshTasks() async {
    if (_selectedProject != null) {
      await _loadTasks(_selectedProject!.id);
    }
  }

  Future<void> _loadTasks(int projectId) async {
    try {
      final tasks = await TaskService.getTasks(projectId);
      setState(() {
        _tasks = tasks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задач: $e')),
      );
    }
  }

  void _selectTask(TaskResponse task) async {
    final taskDetails = await TaskService.getTaskDetails(task.id);
    setState(() {
      _selectedTaskId = task.id.toString();
      _isTaskSelected = true;
      _currentTaskDetails = taskDetails;
    });

    try {
      final trekking = await TaskService.getTrekking(task.id);
      setState(() {
        _currentTrekking = trekking;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки трекинга: $e')),
      );
    }
  }

  void _closeTaskDetails() {
    setState(() {
      _selectedTaskId = null;
      _isTaskSelected = false;
      _currentTaskDetails = null;
      _currentTrekking = null;
      _isCreating = false;
      _isEditing = false;
    });
  }

  void _updateTask(TaskDetailResponse updatedTask) {
    setState(() {
      final index = _tasks.indexWhere((task) => task.id == updatedTask.id);
      if (index != -1) {
        _tasks[index] = TaskResponse.fromDetail(updatedTask);
      }

      if (_currentTaskDetails?.id == updatedTask.id) {
        _currentTaskDetails = updatedTask;
      }
    });

    _stopEditing();
  }

  void _handleTaskCreated(TaskDetailResponse createdTask) {
    final taskResponse = TaskResponse.fromDetail(createdTask);

    setState(() {
      _tasks.insert(0, taskResponse);
      _isCreating = false;
      _currentTaskDetails = createdTask;
    });
  }

  Future<void> _refreshTrekking() async {
    if (_currentTaskDetails != null) {
      try {
        final trekking = await TaskService.getTrekking(_currentTaskDetails!.id);
        setState(() {
          _currentTrekking = trekking;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления трекинга: $e')),
        );
      }
    }
  }

  void _handleTaskAssigned() {
    if (_selectedProject != null) {
      _loadTasks(_selectedProject!.id);
    }

    if (_currentTaskDetails != null) {
      _refreshTaskDetails();
    }
  }

  Future<void> _refreshTaskDetails() async {
    if (_currentTaskDetails != null) {
      try {
        final taskDetails =
            await TaskService.getTaskDetails(_currentTaskDetails!.id);
        final trekking = await TaskService.getTrekking(_currentTaskDetails!.id);

        setState(() {
          _currentTaskDetails = taskDetails;
          _currentTrekking = trekking;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка обновления данных: $e')),
        );
      }
    }
  }

  TrekkingResponse get _emptyTrekking => TrekkingResponse(
        trekkingList: [],
        hourSum: 0.0,
      );

  void _navigateToMembers() {
    Navigator.pushReplacementNamed(context, '/members');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Хедер
          AppHeader(onProjectSelected: _onProjectSelected),

          // Основной контент
          Expanded(
            child: Row(
              children: [
                // 1. Навигационная панель
                SizedBox(
                  width: 100,
                  child: NavigationPanel(
                    isTasksActive: true,
                    isMembersActive: false,
                    onTasksTap: () {}, // Ничего не делаем, т.к. мы уже на этой странице
                    onMembersTap: _navigateToMembers,
                  ),
                ),

                // 2. Список задач
                if (_selectedProject != null)
                  _isTaskSelected
                      ? SizedBox(
                          width: 250,
                          child: TasksListPanel(
                            projectId: _selectedProject!.id,
                            selectedTaskId: _selectedTaskId,
                            onTaskSelected: _selectTask,
                            onAddTask: _startCreating,
                            tasks: _tasks,
                            onTasksUpdated: _refreshTasks,
                          ),
                        )
                      : Expanded(
                          child: TasksListPanel(
                            projectId: _selectedProject!.id,
                            selectedTaskId: _selectedTaskId,
                            onTaskSelected: _selectTask,
                            onAddTask: _startCreating,
                            tasks: _tasks,
                            onTasksUpdated: _refreshTasks,
                          ),
                        )
                else
                  const Expanded(
                    child: Center(child: Text('No project selected')),
                  ),

                // 3. Детали задачи
                if (_isTaskSelected)
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.only(top: 25, bottom: 25),
                      child: _getDetailPanel(),
                    ),
                  ),

                // 4. TaskInfoPanel (показываем всегда когда есть выбранная задача ИЛИ создаем новую)
                if (_isTaskSelected &&
                    (_currentTaskDetails != null || _isCreating))
                  SizedBox(
                    width: 250,
                    child: TaskInfoPanel(
                      task: _isCreating
                          ? (_currentUser != null
                              ? TaskDetailResponse.empty(
                                  projectId: _selectedProject!.id,
                                  currentUser: _currentUser!)
                              : null)
                          : _currentTaskDetails,
                      trekking: _isCreating ? _emptyTrekking : _currentTrekking,
                      onTaskUpdated: _handleTaskAssigned,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getDetailPanel() {
    if (_isCreating) {
      return TaskCreatePanel(
        projectId: _selectedProject!.id,
        onTaskCreated: _handleTaskCreated,
        onClose: _stopCreating,
      );
    } else if (_isEditing && _currentTaskDetails != null) {
      return TaskEditPanel(
        task: _currentTaskDetails!,
        onTaskUpdated: _updateTask,
        onClose: _stopEditing,
        trekking: _currentTrekking,
        onTrekkingUpdated: _refreshTrekking,
        projectId: _selectedProject!.id,
        onSave: _stopEditing,
      );
    } else if (_currentTaskDetails != null) {
      return TaskDetailPanel(
        task: _currentTaskDetails!,
        onTaskUpdated: _updateTask,
        onClose: _closeTaskDetails,
        trekking: _currentTrekking,
        onTrekkingUpdated: _refreshTrekking,
        projectId: _selectedProject!.id,
        onEdit: _startEditing,
      );
    } else {
      return Container(color: Colors.white);
    }
  }
}