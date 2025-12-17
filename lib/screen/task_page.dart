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
import '../widgets/mobile_bottom_nav_bar.dart'; // Добавляем импорт для мобильной навигации

class TasksPage extends StatefulWidget {
  final ProjectResponse? initialProject;
  const TasksPage({Key? key, this.initialProject}) : super(key: key);

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

  // Добавляем методы для мобильной навигации
  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }

  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  void _navigateToMembers() {
    Navigator.pushReplacementNamed(
      context,
      '/members',
      arguments: _selectedProject,
    );
  }

  void _navigateToRepository() {
    Navigator.pushReplacementNamed(
      context,
      '/repository',
      arguments: _selectedProject,
    );
  }

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
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
      _loadTasks(widget.initialProject!.id);
    } else {
      _loadProjects();
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

  void _showMobileProjectSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _buildMobileProjectList();
      },
    );
  }

  Widget _buildMobileProjectList() {
    return FutureBuilder<List<ProjectResponse>>(
      future: ProjectService().getProjects(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.textError,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Нет проектов',
                  style: TextStyle(
                    color: AppColors.textError,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }
        final projects = snapshot.data!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Выберите проект',
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
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  final isSelected = project.id == _selectedProject?.id;
                  return ListTile(
                    leading: Icon(
                      Icons.folder,
                      color:
                          isSelected ? AppColors.primary : AppColors.textHint,
                    ),
                    title: Text(
                      project.name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      _onProjectSelected(project);
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 768;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    if (_selectedProject == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text('Fern.com'),
          centerTitle: true,
          elevation: 2,
        ),
        body: const Center(
          child: Text('Выберите проект'),
        ),
        bottomNavigationBar: MobileBottomNavBar(
          onTasksTap: () {},
          onMembersTap: _navigateToMembers,
          onRepositoryTap: _navigateToRepository,
          onProfileTap: _navigateToProfile,
          onSettingsTap: _navigateToSettings,
          isTasksActive: true,
          isMembersActive: false,
          isRepositoryActive: false,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          _selectedProject?.name ?? 'Fern.com',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        elevation: 2,
        actions: [
          // Кнопка смены проекта на мобильном
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            onPressed: _showMobileProjectSelector,
          ),
        ],
      ),
      body: _isTaskSelected && (_isCreating || _currentTaskDetails != null)
          ? _getMobileDetailPanel()
          : RefreshIndicator(
              onRefresh: _refreshTasks,
              child: TasksListPanel(
                projectId: _selectedProject!.id,
                selectedTaskId: _selectedTaskId,
                onTaskSelected: _selectTask,
                onAddTask: _startCreating,
                tasks: _tasks,
                onTasksUpdated: _refreshTasks,
              ),
            ),
      floatingActionButton: _isTaskSelected
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: _startCreating,
              child: const Icon(Icons.add, color: Colors.white),
            ),
      bottomNavigationBar: MobileBottomNavBar(
        onTasksTap: () {},
        onMembersTap: _navigateToMembers,
        onRepositoryTap: _navigateToRepository,
        onProfileTap: _navigateToProfile,
        onSettingsTap: _navigateToSettings,
        isTasksActive: true,
        isMembersActive: false,
        isRepositoryActive: false,
      ),
    );
  }

  Widget _getMobileDetailPanel() {
    if (_isCreating) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Создать задачу'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _stopCreating,
          ),
        ),
        body: TaskCreatePanel(
          projectId: _selectedProject!.id,
          onTaskCreated: _handleTaskCreated,
          onClose: _stopCreating,
        ),
      );
    } else if (_isEditing && _currentTaskDetails != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Редактировать задачу'),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back), onPressed: _stopEditing),
        ),
        body: TaskEditPanel(
          task: _currentTaskDetails!,
          onTaskUpdated: _updateTask,
          onClose: _stopEditing,
          trekking: _currentTrekking,
          onTrekkingUpdated: _refreshTrekking,
          projectId: _selectedProject!.id,
          onSave: _stopEditing,
          isMobile: true, // ← ОБЯЗАТЕЛЬНО
        ),
      );
    } else if (_currentTaskDetails != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_currentTaskDetails!.name),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _closeTaskDetails,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _startEditing,
            ),
          ],
        ),
        body: TaskDetailPanel(
          task: _currentTaskDetails!,
          onTaskUpdated: _updateTask,
          onClose: _closeTaskDetails,
          trekking: _currentTrekking,
          onTrekkingUpdated: _refreshTrekking,
          projectId: _selectedProject!.id,
          onEdit: _startEditing,
          isMobile: true, // ←←← ЭТО ОБЯЗАТЕЛЬНО!
          onTaskAssigned: _handleTaskAssigned,
        ),
      );
    } else {
      return Container(color: Colors.white);
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Хедер
          AppHeader(
            onProjectSelected: _onProjectSelected,
            initialProject: _selectedProject,
          ),
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
                    isRepositoryActive: false,
                    onTasksTap: () {},
                    onMembersTap: _navigateToMembers,
                    onRepositoryTap: _navigateToRepository,
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
                    child: Center(
                      child: Text('Нет существующих проектов. Создайте чтобы начать работу'),
                    ),
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
                                  currentUser: _currentUser!,
                                )
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
        onTaskAssigned: _handleTaskAssigned,
      );
    } else {
      return Container(color: Colors.white);
    }
  }
}
