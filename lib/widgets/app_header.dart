import 'package:flutter/material.dart';
import '../dto/user/user_response.dart';
import '../dto/project/project_response.dart'; // ← новый импорт
import '../service/main_service.dart';
import '../service/project_service.dart'; // ← новый импорт
import '../utils/token_storage.dart';
import '../theme/colors.dart';
import '../screen/profile_page.dart';

class AppHeader extends StatefulWidget {
  final void Function(ProjectResponse project) onProjectSelected;
  const AppHeader({
    Key? key,
    required this.onProjectSelected, // ← ДОБАВЬ ЭТО
  }) : super(key: key);

  @override
  State<AppHeader> createState() => _AppHeaderState();
}


class _AppHeaderState extends State<AppHeader> {
  UserResponse? _user;
  List<ProjectResponse> _projects = [];
  ProjectResponse? _selectedProject;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final token = await TokenStorage.getToken();
      if (token == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Загружаем профиль и проекты ПАРАЛЛЕЛЬНО
      final profileFuture = MainService().getProfile();
      final projectsFuture = ProjectService().getProjects();

      final user = await profileFuture;
      final projects = await projectsFuture;

      // Выбираем первый проект по умолчанию
      final selectedProject = projects.isNotEmpty ? projects[0] : null;

      setState(() {
        _user = user;
        _projects = projects;
        _selectedProject = selectedProject;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки данных: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Логотип "Popa"
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navigate to home')),
              );
            },
            child: const Text(
              'Popa',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),

          const Spacer(),

          // ComboBox Projects
          _buildProjectsDropdown(),

          const SizedBox(width: 20),

          // Аватар пользователя
          _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildProjectsDropdown() {
    if (_isLoading) {
      return const SizedBox(
        width: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_projects.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Text(
          'No Projects',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ProjectResponse>(
          value: _selectedProject,
          isDense: true,
          underline: const SizedBox(),
          icon: Icon(Icons.arrow_drop_down, color: AppColors.textHint),
          items: _projects.map((project) {
            return DropdownMenuItem<ProjectResponse>(
              value: project,
              child: Text(
                project.name,
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (ProjectResponse? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedProject = newValue;
              });

              // 🔜 СЮДА БУДЕМ ПОДКЛЮЧАТЬ ЗАГРУЗКУ ЗАДАЧ
              _onProjectSelected(newValue);
            }
          },
        ),
      ),
    );
  }

  void _onProjectSelected(ProjectResponse project) {
    widget.onProjectSelected(project);
    print('Выбран проект: ${project.name} (ID: ${project.id})');
  }

  Widget _buildUserAvatar() {
  return GestureDetector(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    },
    child: _isLoading
        ? Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
            ),
          )
        : _user?.hasProfileImage == true
            ? Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(child: _user!.avatarWidget),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person,
                  color: AppColors.primary,
                ),
              ),
  );
}
}