// lib/screen/profile/profile_page.dart
import 'package:flutter/material.dart';
import 'package:it_planner/dto/tracking/user_tracking_response.dart';
import 'package:it_planner/screen/profile/widgets/pricing_section.dart';
import 'package:it_planner/screen/profile/widgets/tracking_section.dart';
import '../../widgets/mobile_bottom_nav_bar.dart';
import '../../dto/user/user_response.dart';
import '../../dto/project/project_response.dart';
import '../../dto/task/task_response.dart';
import '../../dto/ai/ai_response_history.dart';
import '../../service/main_service.dart';
import '../../service/project_service.dart';
import '../../service/task_service.dart';
import '../../service/ai_service.dart';
import '../../utils/token_storage.dart';
import '../../theme/colors.dart';
import '../auth/login_screen.dart';
import 'widgets/profile_section.dart';
import 'widgets/projects_section.dart';
import 'widgets/tasks_section.dart';
import 'widgets/ai_responses_section.dart';
import 'widgets/desktop_navigation.dart';
import 'widgets/mobile_tab_button.dart';
import 'widgets/dialogs/create_project_dialog.dart';
import 'widgets/dialogs/delete_project_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserResponse? _user;
  List<ProjectResponse> _myProjects = [];
  List<TaskResponse> _myTasks = [];
  List<AIResponseHistory> _aiResponses = [];
  UserTrackingResponse? _trackingData;
  bool _isLoading = true;
  bool _isEditingProfile = false;
  String _activeSection = 'profile';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userFuture = MainService().getProfile();
      final projectsFuture = ProjectService().getMyProjects();
      final tasksFuture = TaskService.getMyTasks();
      final aiResponsesFuture = AIService.getAIResponseHistory();
      final trackingFuture = TaskService.getUserTracking(); // Добавляем

      final results = await Future.wait([
        userFuture,
        projectsFuture,
        tasksFuture,
        aiResponsesFuture,
        trackingFuture, // Добавляем
      ]);

      setState(() {
        _user = results[0] as UserResponse;
        _myProjects = results[1] as List<ProjectResponse>;
        _myTasks = results[2] as List<TaskResponse>;
        _aiResponses = results[3] as List<AIResponseHistory>;
        _trackingData = results[4] as UserTrackingResponse; // Добавляем
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных профиля: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки данных: $e')),
      );
    }
  }

  void _goBackToTasks() {
    Navigator.of(context).pop();
  }

  Future<void> _logout() async {
    await TokenStorage.clearToken();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
      (route) => false,
    );
  }

  void _toggleEditProfile() {
    setState(() {
      _isEditingProfile = !_isEditingProfile;
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditingProfile = false;
    });
  }

  Future<void> _createProject(String name) async {
    try {
      await ProjectService().createProject(name);
      await _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Проект "$name" создан'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка создания проекта: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteProject(int projectId, String projectName) async {
    showDialog(
      context: context,
      builder: (context) => DeleteProjectDialog(
        projectName: projectName,
        onDelete: () async {
          try {
            await ProjectService().deleteProject(projectId);
            await _loadData();
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Проект "$projectName" удален'),
                backgroundColor: Colors.green,
              ),
            );
          } catch (e) {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка удаления проекта: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      ),
    );
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(
        onCreateProject: _createProject,
      ),
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Профиль'),
        centerTitle: true,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: _logout,
            tooltip: 'Выйти',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user != null
              ? _buildMobileContent()
              : const Center(child: Text('Профиль не загружен')),
      bottomNavigationBar: MobileBottomNavBar(
        onTasksTap: _goBackToTasks,
        onMembersTap: () => Navigator.pushReplacementNamed(context, '/members'),
        onRepositoryTap: () =>
            Navigator.pushReplacementNamed(context, '/repository'),
        onArchiveTap: () => Navigator.pushReplacementNamed(context, '/archive'),
        onProfileTap: () {},
        onSettingsTap: () => Navigator.pushNamed(context, '/settings'),
        isArchiveActive: false,
        isTasksActive: false,
        isMembersActive: false,
        isRepositoryActive: false,
      ),
    );
  }

  // lib/screen/profile/profile_page.dart

// В методе _buildMobileContent() добавляем новую кнопку:
  Widget _buildMobileContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: AppColors.cardBorder),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                MobileTabButton(
                  label: 'Профиль',
                  isActive: _activeSection == 'profile',
                  onTap: () => setState(() => _activeSection = 'profile'),
                ),
                MobileTabButton(
                  label: 'Проекты',
                  isActive: _activeSection == 'projects',
                  onTap: () => setState(() => _activeSection = 'projects'),
                ),
                MobileTabButton(
                  label: 'Задачи',
                  isActive: _activeSection == 'tasks',
                  onTap: () => setState(() => _activeSection = 'tasks'),
                ),
                MobileTabButton(
                  label: 'Трекинг', // Новая кнопка
                  isActive: _activeSection == 'tracking',
                  onTap: () => setState(() => _activeSection = 'tracking'),
                ),
                MobileTabButton(
                  label: 'Тарифы', // ← НОВАЯ ВКЛАДКА
                  isActive: _activeSection == 'pricing',
                  onTap: () => setState(() => _activeSection = 'pricing'),
                ),
                MobileTabButton(
                  label: 'Ответы ИИ',
                  isActive: _activeSection == 'ai',
                  onTap: () => setState(() => _activeSection = 'ai'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildSectionContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionContent() {
    switch (_activeSection) {
      case 'profile':
        return ProfileSection(
          user: _user!,
          isEditing: _isEditingProfile,
          onEditToggle: _toggleEditProfile,
          onCancelEdit: _cancelEdit,
          onProfileUpdated: _loadData,
          isMobile: true,
          projectsCount: _myProjects.length,
          tasksCount: _myTasks.length,
        );
      case 'projects':
        return ProjectsSection(
          projects: _myProjects,
          onCreateProject: _showCreateProjectDialog,
          onDeleteProject: _deleteProject,
        );
      case 'pricing': // ← НОВЫЙ CASE
        return PricingSection(
          currentPlan: 'basic', // Пока моковые данные
          aiRequestsUsed: 2,
          aiRequestsLimit: 3,
        );
      case 'tasks':
        return TasksSection(tasks: _myTasks);
      case 'tracking': // ВОТ ЭТОГО НЕ ХВАТАЛО!
        return _trackingData != null
            ? TrackingSection(trackingData: _trackingData!)
            : const Center(child: CircularProgressIndicator());
      case 'ai':
        return AIResponsesSection(responses: _aiResponses);
      default:
        return const SizedBox();
    }
  }

// В ProfilePage, в _buildDesktopLayout:
  Widget _buildDesktopLayout() {
    print('=== _buildDesktopLayout, activeSection: $_activeSection ===');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Левая навигация
          SizedBox(
            width: 280,
            child: DesktopNavigation(
              activeSection: _activeSection,
              onSectionChanged: (section) {
                print('=== onSectionChanged: $section ===');
                setState(() {
                  _activeSection = section;
                });
              },
              onBack: _goBackToTasks,
              onLogout: _logout,
            ),
          ),
          // Правая часть - ВАЖНО: используем Expanded
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _user != null
                    ? _buildSectionContent() // ПРЯМОЙ ВЫЗОВ без лишних оберток
                    : const Center(child: Text('Профиль не загружен')),
          ),
        ],
      ),
    );
  }
}
