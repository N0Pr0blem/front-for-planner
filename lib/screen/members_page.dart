import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/members_list_panel.dart';
import '../widgets/member_detail_panel.dart';
import '../widgets/invite_member_dialog.dart';
import '../widgets/mobile_bottom_nav_bar.dart';
import '../theme/colors.dart';
import '../dto/project/project_response.dart';
import '../dto/project/project_member_response.dart';
import '../service/project_service.dart';
import '../service/project_member_service.dart';

class MembersPage extends StatefulWidget {
  final ProjectResponse? initialProject;
  
  const MembersPage({
    Key? key, 
    this.initialProject
  }) : super(key: key);
  
  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  ProjectResponse? _selectedProject;
  ProjectMemberResponse? _selectedMember;
  bool _isMemberSelected = false;
  List<ProjectMemberResponse> _members = [];
  
  // Добавляем для мобильной навигации
  void _navigateToProfile() {
    Navigator.pushNamed(context, '/profile');
  }
  
  void _navigateToSettings() {
    Navigator.pushNamed(context, '/settings');
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialProject != null) {
      _selectedProject = widget.initialProject;
      _loadMembers(widget.initialProject!.id);
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
      _loadMembers(selected.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки проектов: $e'),
        ),
      );
    }
  }

  void _onProjectSelected(ProjectResponse project) {
    setState(() {
      _selectedProject = project;
    });
    _loadMembers(project.id);
  }

  Future<void> _refreshMembers() async {
    if (_selectedProject != null) {
      await _loadMembers(_selectedProject!.id);
    }
  }

  Future<void> _loadMembers(int projectId) async {
    try {
      print('Loading members for project: $projectId');
      final members = await ProjectMemberService().getProjectMembers(projectId);
      print('Successfully loaded ${members.length} members');
      setState(() {
        _members = members;
      });
    } catch (e) {
      print('Error loading members: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки участников: $e'),
        ),
      );
    }
  }

  void _selectMember(ProjectMemberResponse member) {
    setState(() {
      _selectedMember = member;
      _isMemberSelected = true;
    });
  }

  void _closeMemberDetails() {
    setState(() {
      _selectedMember = null;
      _isMemberSelected = false;
    });
  }

  void _onMemberUpdated() {
    if (_selectedProject != null) {
      _loadMembers(_selectedProject!.id);
    }
  }

  void _onMemberRemoved() {
    _closeMemberDetails();
    if (_selectedProject != null) {
      _loadMembers(_selectedProject!.id);
    }
  }

  void _navigateToTasks() {
    Navigator.pushReplacementNamed(
      context, 
      '/tasks',
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
          onMembersTap: () {},
          onRepositoryTap: _navigateToRepository,
          onProfileTap: _navigateToProfile,
          onSettingsTap: _navigateToSettings,
          isTasksActive: false,
          isMembersActive: true,
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
      body: _isMemberSelected && _selectedMember != null
          ? MemberDetailPanel(
              member: _selectedMember!,
              projectId: _selectedProject!.id,
              onMemberUpdated: _onMemberUpdated,
              onMemberRemoved: _onMemberRemoved,
              onClose: _closeMemberDetails,
              isMobile: true,
            )
          : RefreshIndicator(
              onRefresh: _refreshMembers,
              child: MembersListPanel(
                projectId: _selectedProject!.id,
                selectedMemberId: _selectedMember?.id.toString(),
                onMemberSelected: _selectMember,
                onAddMember: _refreshMembers,
                members: _members,
                onMembersUpdated: _refreshMembers,
                isMobile: true,
              ),
            ),
      floatingActionButton: _isMemberSelected 
          ? null
          : FloatingActionButton(
              backgroundColor: AppColors.primary,
              onPressed: () => _showInviteDialog(context),
              child: const Icon(Icons.person_add, color: Colors.white),
            ),
      bottomNavigationBar: MobileBottomNavBar(
        onTasksTap: _navigateToTasks,
        onMembersTap: () {},
        onRepositoryTap: _navigateToRepository,
        onProfileTap: _navigateToProfile,
        onSettingsTap: _navigateToSettings,
        isTasksActive: false,
        isMembersActive: true,
        isRepositoryActive: false,
      ),
    );
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
                    isTasksActive: false,
                    isMembersActive: true,
                    isRepositoryActive: false,
                    onTasksTap: _navigateToTasks,
                    onMembersTap: () {},
                    onRepositoryTap: _navigateToRepository,
                  ),
                ),
                // 2. Список участников
                if (_selectedProject != null)
                  _isMemberSelected
                      ? SizedBox(
                          width: 350,
                          child: MembersListPanel(
                            projectId: _selectedProject!.id,
                            selectedMemberId: _selectedMember?.id.toString(),
                            onMemberSelected: _selectMember,
                            onAddMember: _refreshMembers,
                            members: _members,
                            onMembersUpdated: _refreshMembers,
                          ),
                        )
                      : Expanded(
                          child: MembersListPanel(
                            projectId: _selectedProject!.id,
                            selectedMemberId: _selectedMember?.id.toString(),
                            onMemberSelected: _selectMember,
                            onAddMember: _refreshMembers,
                            members: _members,
                            onMembersUpdated: _refreshMembers,
                          ),
                        )
                else
                  const Expanded(
                    child: Center(
                      child: Text('No project selected'),
                    ),
                  ),
                // 3. Детали участника
                if (_isMemberSelected && _selectedMember != null)
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.only(top: 25, bottom: 25),
                      child: MemberDetailPanel(
                        member: _selectedMember!,
                        projectId: _selectedProject!.id,
                        onMemberUpdated: _onMemberUpdated,
                        onMemberRemoved: _onMemberRemoved,
                        onClose: _closeMemberDetails,
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
                      color: isSelected 
                        ? AppColors.primary 
                        : AppColors.textHint,
                    ),
                    title: Text(
                      project.name,
                      style: TextStyle(
                        fontWeight: isSelected 
                          ? FontWeight.bold 
                          : FontWeight.normal,
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

  void _showInviteDialog(BuildContext context) {
    if (MediaQuery.of(context).size.width < 768) {
      // Мобильная версия
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
            child: InviteMemberDialog(
              projectId: _selectedProject!.id,
              onMemberInvited: () {
                _refreshMembers();
                Navigator.pop(context);
              },
            ),
          );
        },
      );
    } else {
      // Десктоп версия
      showDialog(
        context: context,
        builder: (context) {
          return InviteMemberDialog(
            projectId: _selectedProject!.id,
            onMemberInvited: () {
              _refreshMembers();
              Navigator.pop(context);
            },
          );
        },
      );
    }
  }
}