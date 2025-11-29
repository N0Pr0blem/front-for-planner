import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/navigation_panel.dart';
import '../widgets/members_list_panel.dart';
import '../widgets/member_detail_panel.dart';
import '../theme/colors.dart';
import '../dto/project/project_response.dart';
import '../dto/project/project_member_response.dart';
import '../service/project_service.dart';
import '../service/project_member_service.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({Key? key}) : super(key: key);

  @override
  _MembersPageState createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  ProjectResponse? _selectedProject;
  ProjectMemberResponse? _selectedMember;
  bool _isMemberSelected = false;
  List<ProjectMemberResponse> _members = [];

  @override
  void initState() {
    super.initState();
    _loadProjects();
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
        SnackBar(content: Text('Ошибка загрузки проектов: $e')),
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
      final members = await ProjectMemberService().getProjectMembers(projectId);
      setState(() {
        _members = members;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки участников: $e')),
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
    Navigator.pushReplacementNamed(context, '/tasks');
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
                    isTasksActive: false,
                    isMembersActive: true,
                    onTasksTap: _navigateToTasks,
                    onMembersTap: () {}, // Ничего не делаем, т.к. мы уже на этой странице
                  ),
                ),

                // 2. Список участников
                if (_selectedProject != null)
                  _isMemberSelected
                      ? SizedBox(
                          width: 250,
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
                    child: Center(child: Text('No project selected')),
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
}