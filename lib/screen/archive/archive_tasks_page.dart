// lib/screen/archive_tasks_page.dart
import 'package:flutter/material.dart';
import 'package:it_planner/dto/project/project_response.dart';
import 'package:it_planner/dto/task/task_detail_response.dart';
import 'package:it_planner/dto/task/task_response.dart';
import 'package:it_planner/screen/archive/widgets/archive_tasks_list_panel.dart';
import 'package:it_planner/screen/archive/widgets/archive_task_detail_panel.dart';
import 'package:it_planner/screen/archive/widgets/archive_task_info_panel.dart';
import 'package:it_planner/service/project_service.dart';
import 'package:it_planner/service/task_service.dart';
import 'package:it_planner/theme/colors.dart';
import 'package:it_planner/widgets/app_header.dart';
import 'package:it_planner/widgets/mobile_bottom_nav_bar.dart';
import 'package:it_planner/widgets/navigation_panel.dart';

class ArchiveTasksPage extends StatefulWidget {
  final ProjectResponse? initialProject;
  
  const ArchiveTasksPage({Key? key, this.initialProject}) : super(key: key);

  @override
  _ArchiveTasksPageState createState() => _ArchiveTasksPageState();
}

class _ArchiveTasksPageState extends State<ArchiveTasksPage> {
  ProjectResponse? _selectedProject;
  String? _selectedTaskId;
  TaskDetailResponse? _currentTaskDetails;
  bool _isTaskSelected = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Создайте первый проект чтобы начать работу')),
      );
    }
  }

  void _onProjectSelected(ProjectResponse project) {
    setState(() {
      _selectedProject = project;
    });
  }

  void _selectTask(TaskResponse task) async {
    try {
      final taskDetails = await TaskService.getTaskDetails(task.id);
      setState(() {
        _selectedTaskId = task.id.toString();
        _isTaskSelected = true;
        _currentTaskDetails = taskDetails;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки задачи: $e')),
      );
    }
  }

  void _closeTaskDetails() {
    setState(() {
      _selectedTaskId = null;
      _isTaskSelected = false;
      _currentTaskDetails = null;
    });
  }

  void _handleTaskRestored() {
    _closeTaskDetails();
  }

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

  void _navigateToTasks() {
    Navigator.pushReplacementNamed(
      context,
      '/tasks',
      arguments: _selectedProject,
    );
  }

  void _navigateToArchive() {
    // Уже на странице архива
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
          onTasksTap: _navigateToTasks,
          onMembersTap: _navigateToMembers,
          onRepositoryTap: _navigateToRepository,
          onArchiveTap: _navigateToArchive,
          onProfileTap: _navigateToProfile,
          onSettingsTap: _navigateToSettings,
          isTasksActive: false,
          isMembersActive: false,
          isRepositoryActive: false,
          isArchiveActive: true,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Архив - ${_selectedProject?.name ?? ''}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 2,
      ),
      body: _isTaskSelected && _currentTaskDetails != null
          ? ArchiveTaskDetailPanel(
              task: _currentTaskDetails!,
              onClose: _closeTaskDetails,
              onRestored: _handleTaskRestored,
              isMobile: true,
            )
          : ArchiveTasksListPanel(
              projectId: _selectedProject!.id,
              selectedTaskId: _selectedTaskId,
              onTaskSelected: _selectTask,
              isMobile: true,
            ),
      bottomNavigationBar: MobileBottomNavBar(
        onTasksTap: _navigateToTasks,
        onMembersTap: _navigateToMembers,
        onRepositoryTap: _navigateToRepository,
        onArchiveTap: _navigateToArchive,
        onProfileTap: _navigateToProfile,
        onSettingsTap: _navigateToSettings,
        isTasksActive: false,
        isMembersActive: false,
        isRepositoryActive: false,
        isArchiveActive: true,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          AppHeader(
            onProjectSelected: _onProjectSelected,
            initialProject: _selectedProject,
          ),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: NavigationPanel(
                    isTasksActive: false,
                    isMembersActive: false,
                    isRepositoryActive: false,
                    onTasksTap: _navigateToTasks,
                    onMembersTap: _navigateToMembers,
                    onRepositoryTap: _navigateToRepository,
                    showArchive: true,
                    isArchiveActive: true,
                    onArchiveTap: () {},
                  ),
                ),
                if (_selectedProject != null)
                  _isTaskSelected
                      ? SizedBox(
                          width: 350,
                          child: ArchiveTasksListPanel(
                            projectId: _selectedProject!.id,
                            selectedTaskId: _selectedTaskId,
                            onTaskSelected: _selectTask,
                          ),
                        )
                      : Expanded(
                          child: ArchiveTasksListPanel(
                            projectId: _selectedProject!.id,
                            selectedTaskId: _selectedTaskId,
                            onTaskSelected: _selectTask,
                          ),
                        )
                else
                  const Expanded(
                    child: Center(
                      child: Text('Нет существующих проектов. Создайте чтобы начать работу'),
                    ),
                  ),
                if (_isTaskSelected && _currentTaskDetails != null)
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.only(top: 25, bottom: 25),
                      child: ArchiveTaskDetailPanel(
                        task: _currentTaskDetails!,
                        onClose: _closeTaskDetails,
                        onRestored: _handleTaskRestored,
                      ),
                    ),
                  ),
                if (_isTaskSelected && _currentTaskDetails != null)
                  SizedBox(
                    width: 250,
                    child: ArchiveTaskInfoPanel(
                      task: _currentTaskDetails!,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}