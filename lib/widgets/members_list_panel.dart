import 'package:flutter/material.dart';
import '../dto/project/project_member_response.dart';
import '../theme/colors.dart';
import 'dart:convert';
import 'invite_member_dialog.dart'; // Добавляем импорт

class MembersListPanel extends StatefulWidget {
  final int projectId;
  final String? selectedMemberId;
  final Function(ProjectMemberResponse) onMemberSelected;
  final VoidCallback onAddMember;
  final List<ProjectMemberResponse> members;
  final VoidCallback? onMembersUpdated;

  const MembersListPanel({
    Key? key,
    required this.projectId,
    required this.selectedMemberId,
    required this.onMemberSelected,
    required this.onAddMember,
    required this.members,
    this.onMembersUpdated,
  }) : super(key: key);

  @override
  State<MembersListPanel> createState() => _MembersListPanelState();
}

class _MembersListPanelState extends State<MembersListPanel> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.members.isEmpty) {
      _loadInitialMembers();
    }
  }

  Future<void> _loadInitialMembers() async {
    try {
      if (widget.onMembersUpdated != null) {
        widget.onMembersUpdated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки участников: $e')),
      );
    }
  }

  Future<void> _refreshMembers() async {
    try {
      if (widget.onMembersUpdated != null) {
        widget.onMembersUpdated!();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления участников: $e')),
      );
    }
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InviteMemberDialog( // Используем именованный класс
          projectId: widget.projectId,
          onMemberInvited: () {
            _refreshMembers();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Пользователь приглашен'),
                backgroundColor: Colors.green,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    onTap: () {
                      _showInviteDialog(context);
                    },
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
                      hintText: 'Search members...',
                      hintStyle: const TextStyle(color: AppColors.textHint),
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12),
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
          // Список участников
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshMembers,
              child: widget.members.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет участников',
                        style: TextStyle(
                          color: AppColors.textHint,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: widget.members.length,
                      itemBuilder: (context, index) {
                        final member = widget.members[index];
                        final isSelected = member.id.toString() == widget.selectedMemberId;
                        return _MemberListItem(
                          member: member,
                          isSelected: isSelected,
                          onTap: () => widget.onMemberSelected(member),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberListItem extends StatelessWidget {
  final ProjectMemberResponse member;
  final bool isSelected;
  final VoidCallback onTap;

  const _MemberListItem({
    Key? key,
    required this.member,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(color: AppColors.cardBorder.withOpacity(0.5)),
        boxShadow: isSelected
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
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Аватар
                if (member.user.hasAvatar)
                  ClipOval(
                    child: Image.memory(
                      base64Decode(member.user.profileImage!),
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _defaultAvatar();
                      },
                    ),
                  )
                else
                  _defaultAvatar(),
                
                const SizedBox(width: 12),
                
                // Информация
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.user.fullName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRoleDisplayName(member.projectRole),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: 20,
        color: AppColors.primary,
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'PROJECT_MANAGER':
        return 'Project Manager';
      case 'FRONTEND_DEVELOPER':
        return 'Frontend Developer';
      case 'BACKEND_DEVELOPER':
        return 'Backend Developer';
      case 'TESTER':
        return 'Tester';
      case 'UI_UX_DESIGNER':
        return 'UI/UX Designer';
      case 'DEVOPS':
        return 'DevOps';
      case 'ANOTHER':
        return 'Another';
      default:
        return role;
    }
  }
}