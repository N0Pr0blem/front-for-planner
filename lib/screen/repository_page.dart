import 'package:flutter/material.dart';
import '../dto/project/project_response.dart';
import '../dto/repository/repository_file_response.dart';
import '../service/repository_service.dart';
import '../service/project_service.dart'; // Добавляем импорт
import '../theme/colors.dart';
import '../widgets/app_header.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/upload_file_dialog.dart';
import '../widgets/delete_file_dialog.dart';
import '../widgets/repository_file_item.dart';

class RepositoryPage extends StatefulWidget {
  final ProjectResponse? initialProject;
  const RepositoryPage({Key? key,this.initialProject}) : super(key: key);

  @override
  _RepositoryPageState createState() => _RepositoryPageState();
}

class _RepositoryPageState extends State<RepositoryPage> {
  ProjectResponse? _selectedProject;
  List<RepositoryFileResponse> _files = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
      _loadRepositoryFiles(widget.initialProject!.id);
    } else {
      _loadProjects();
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ProjectService().getProjects();
      if (projects.isNotEmpty) {
        final selectedProject = projects[0];
        setState(() {
          _selectedProject = selectedProject;
        });
        _loadRepositoryFiles(selectedProject.id);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка загрузки проектов: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onProjectSelected(ProjectResponse project) {
    setState(() {
      _selectedProject = project;
    });
    _loadRepositoryFiles(project.id);
  }

  Future<void> _loadRepositoryFiles(int projectId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final files = await RepositoryService().getRepositoryFiles(projectId);
      setState(() {
        _files = files;
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки файлов: $e')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshFiles() async {
    if (_selectedProject != null) {
      await _loadRepositoryFiles(_selectedProject!.id);
    }
  }

  void _showUploadDialog() {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сначала выберите проект')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return UploadFileDialog(
          projectId: _selectedProject!.id,
          onFileUploaded: _refreshFiles,
        );
      },
    );
  }

  void _showDeleteDialog(RepositoryFileResponse file) {
    if (_selectedProject == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return DeleteFileDialog(
          projectId: _selectedProject!.id,
          file: file,
          onFileDeleted: _refreshFiles,
        );
      },
    );
  }

  Future<void> _downloadFile(RepositoryFileResponse file) async {
    if (_selectedProject == null) return;

    try {
      await RepositoryService()
          .downloadFile(_selectedProject!.id, file.id, file.name);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Файл "${file.displayName}" скачан')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка скачивания: $e')),
      );
    }
  }

  void _navigateToTasks() {
    Navigator.pushReplacementNamed(context, '/tasks',
        arguments: _selectedProject);
  }

  void _navigateToMembers() {
    Navigator.pushReplacementNamed(context, '/members',
        arguments: _selectedProject);
  }

  void _navigateToRepository() {}

  @override
  Widget build(BuildContext context) {
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
                    isRepositoryActive: true,
                    onTasksTap: _navigateToTasks,
                    onMembersTap: _navigateToMembers,
                    onRepositoryTap: _navigateToRepository,
                  ),
                ),
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Шапка с кнопкой добавления и поиском
                        Row(
                          children: [
                            // Кнопка добавления
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
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: _showUploadDialog,
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      gradient: AppGradients.primaryButton,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      color: AppColors.textOnPrimary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Поле поиска
                            Expanded(
                              child: Container(
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Colors.white,
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
                                child: TextField(
                                  controller: _searchController,
                                  decoration: InputDecoration(
                                    hintText: 'Search files...',
                                    hintStyle: const TextStyle(
                                        color: AppColors.textHint),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: AppColors.textHint,
                                      size: 20,
                                    ),
                                  ),
                                  style: const TextStyle(fontSize: 14),
                                  onChanged: (value) {
                                    // Можно добавить фильтрацию
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Список файлов
                        Expanded(
                          child: _buildContent(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_selectedProject == null) {
      return const Center(
        child: Text(
          'Нет доступных проектов',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 16,
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(
        child: Text(
          'Файлы репозитория отсутствуют',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 16,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshFiles,
      child: ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return RepositoryFileItem(
            file: file,
            onDownload: () => _downloadFile(file),
            onDelete: () => _showDeleteDialog(file),
          );
        },
      ),
    );
  }
}
