import 'package:flutter/material.dart';
import '../dto/project/project_member_response.dart';
import '../theme/colors.dart';
import 'invite_member_dialog.dart';
import 'dart:convert'; 

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
    print('🎯 MembersListPanel initialized with ${widget.members.length} members');
    for (var i = 0; i < widget.members.length; i++) {
      final member = widget.members[i];
      print('🎯 Member $i: ${member.user.fullName} - ${member.user.firstName} ${member.user.secondName}');
    }
  }

  Future<void> _refreshMembers() async {
    try {
      if (widget.onMembersUpdated != null) {
        widget.onMembersUpdated!();
      }
    } catch (e) {
      print('Error in _refreshMembers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка обновления участников: $e')),
      );
    }
  }

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InviteMemberDialog(
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
              child: _buildMembersList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    if (widget.members.isEmpty) {
      return const Center(
        child: Text(
          'Нет участников',
          style: TextStyle(
            color: AppColors.textHint,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: widget.members.length,
      itemBuilder: (context, index) {
        final member = widget.members[index];
        
        print('🎯 Building member $index: ${member.user.fullName}');
        
        // Безопасная проверка
        try {
          final isSelected = member.id.toString() == widget.selectedMemberId;
          return _SafeMemberListItem(
            member: member,
            isSelected: isSelected,
            onTap: () => widget.onMemberSelected(member),
          );
        } catch (e) {
          print('❌ Error building member item at index $index: $e');
          return _ErrorMemberListItem(
            error: e.toString(),
            index: index,
          );
        }
      },
    );
  }
}

class _SafeMemberListItem extends StatelessWidget {
  final ProjectMemberResponse member;
  final bool isSelected;
  final VoidCallback onTap;

  const _SafeMemberListItem({
    Key? key,
    required this.member,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🎯 Rendering member: ${member.user.fullName}');
    
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
                _buildAvatar(),
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

  Widget _buildAvatar() {
    try {
      if (member.user.hasAvatar) {
        return ClipOval(
          child: Image.memory(
            base64Decode(member.user.profileImage!),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('❌ Error loading avatar: $error');
              return _defaultAvatar();
            },
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _buildAvatar: $e');
    }
    return _defaultAvatar();
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

class _ErrorMemberListItem extends StatelessWidget {
  final String error;
  final int index;

  const _ErrorMemberListItem({
    Key? key,
    required this.error,
    required this.index,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error loading member $index',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  error,
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}