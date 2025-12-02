import 'package:flutter/material.dart';
import 'dart:convert'; // Добавляем для base64 декодирования
import '../theme/colors.dart';
import '../dto/project/project_member_response.dart';
import 'invite_member_dialog.dart';

class MembersListPanel extends StatelessWidget {
  final int projectId;
  final String? selectedMemberId;
  final Function(ProjectMemberResponse) onMemberSelected;
  final VoidCallback onAddMember;
  final List<ProjectMemberResponse> members;
  final VoidCallback onMembersUpdated;
  final bool isMobile;

  const MembersListPanel({
    Key? key,
    required this.projectId,
    this.selectedMemberId,
    required this.onMemberSelected,
    required this.onAddMember,
    required this.members,
    required this.onMembersUpdated,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isMemberSelected = selectedMemberId != null && selectedMemberId!.isNotEmpty;
    
    return Container(
      color: AppColors.background,
      padding: isMobile
          ? const EdgeInsets.all(16)
          : const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Участники проекта',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Если участник выбран, показываем иконку вместо кнопки
                  isMemberSelected
                      ? IconButton(
                          onPressed: () => _showInviteDialog(context),
                          icon: Icon(
                            Icons.person_add,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          tooltip: 'Пригласить участника',
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        )
                      : ElevatedButton.icon(
                          onPressed: () => _showInviteDialog(context),
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Пригласить'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                ],
              ),
            ),
          ],
          if (isMobile) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Участники (${members.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.person_add, color: AppColors.primary),
                  onPressed: () => _showInviteDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.textHint.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет участников',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (!isMobile && !isMemberSelected)
                          TextButton(
                            onPressed: () => _showInviteDialog(context),
                            child: const Text('Пригласить первого участника'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      final isSelected = selectedMemberId == member.id.toString();
                      if (isMobile) {
                        return _buildMobileMemberCard(member, context);
                      } else {
                        return _buildDesktopMemberCard(member, context, isSelected);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileMemberCard(
    ProjectMemberResponse member,
    BuildContext context,
  ) {
    final user = member.user;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: _buildUserAvatar(user, 40),
        title: Text(
          user.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          _getRoleName(member.projectRole),
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textHint,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.textHint,
        ),
        onTap: () => onMemberSelected(member),
      ),
    );
  }

  Widget _buildDesktopMemberCard(
    ProjectMemberResponse member,
    BuildContext context,
    bool isSelected,
  ) {
    final user = member.user;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? AppColors.primary
              : AppColors.cardBorder.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onMemberSelected(member),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildUserAvatar(user, 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getRoleName(member.projectRole),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildUserAvatar(UserInfoForTaskDto user, double size) {
  if (user.hasAvatar && user.profileImage != null && user.profileImage!.isNotEmpty) {
    try {
      return SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: Image.memory(
            base64Decode(user.profileImage!),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(size);
            },
          ),
        ),
      );
    } catch (e) {
      return _buildDefaultAvatar(size);
    }
  }
  
  return _buildDefaultAvatar(size);
}

  Widget _buildDefaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color: AppColors.primary,
      ),
    );
  }

  String _getRoleName(String role) {
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

  void _showInviteDialog(BuildContext context) {
    if (isMobile) {
      // Для мобильных используем bottom sheet
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
              projectId: projectId,
              onMemberInvited: onMembersUpdated,
            ),
          );
        },
      );
    } else {
      // Для десктоп используем dialog
      showDialog(
        context: context,
        builder: (context) {
          return InviteMemberDialog(
            projectId: projectId,
            onMemberInvited: onMembersUpdated,
          );
        },
      );
    }
  }
}