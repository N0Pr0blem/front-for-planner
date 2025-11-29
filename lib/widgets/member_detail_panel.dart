import 'package:flutter/material.dart';
import '../dto/project/project_member_response.dart';
import '../theme/colors.dart';
import '../service/project_member_service.dart';
import 'dart:convert';
import 'change_role_dialog.dart'; // Добавляем импорт

class MemberDetailPanel extends StatefulWidget {
  final ProjectMemberResponse member;
  final int projectId;
  final VoidCallback onMemberUpdated;
  final VoidCallback onMemberRemoved;
  final VoidCallback onClose;

  const MemberDetailPanel({
    Key? key,
    required this.member,
    required this.projectId,
    required this.onMemberUpdated,
    required this.onMemberRemoved,
    required this.onClose,
  }) : super(key: key);

  @override
  _MemberDetailPanelState createState() => _MemberDetailPanelState();
}

class _MemberDetailPanelState extends State<MemberDetailPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showRemoveConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Выгнать участника'),
          content: Text('Вы уверены, что хотите выгнать ${widget.member.user.fullName} из проекта?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeMember();
              },
              child: Text(
                'Выгнать',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeMember() async {
    try {
      await ProjectMemberService().removeMember(
        widget.projectId,
        widget.member.id,
      );
      widget.onMemberRemoved();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Участник удален из проекта'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления участника: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChangeRoleDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeRoleDialog( // Используем именованный класс
          currentRole: widget.member.projectRole,
          projectId: widget.projectId,
          memberId: widget.member.id,
          onRoleChanged: () {
            widget.onMemberUpdated();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Роль обновлена'),
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
    final member = widget.member;

    return Container(
      color: Colors.white,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ВЕРХНИЙ БЛОК С КРЕСТИКОМ
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              member.user.fullName,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          FadeTransition(
                            opacity: _fadeAnimation,
                            child: ScaleTransition(
                              scale: _scaleAnimation,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: AppColors.textHint,
                                  size: 28,
                                ),
                                onPressed: widget.onClose,
                                splashRadius: 24,
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Контент
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Аватар и основная информация
                          _MemberAvatarSection(member: member),
                          
                          const SizedBox(height: 24),

                          // Роль
                          _RoleSection(
                            role: member.projectRole,
                            onChangeRole: _showChangeRoleDialog,
                          ),

                          const SizedBox(height: 32),

                          // Кнопка выгона
                          _RemoveMemberButton(
                            onRemove: _showRemoveConfirmationDialog,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MemberAvatarSection extends StatelessWidget {
  final ProjectMemberResponse member;

  const _MemberAvatarSection({
    Key? key,
    required this.member,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          // Аватар
          if (member.user.hasAvatar)
            ClipOval(
              child: Image.memory(
                base64Decode(member.user.profileImage!),
                width: 120,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _defaultAvatar(120);
                },
              ),
            )
          else
            _defaultAvatar(120),
          
          const SizedBox(height: 16),
          
          // Имя
          Text(
            member.user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.person,
        size: size * 0.5,
        color: AppColors.primary,
      ),
    );
  }
}

class _RoleSection extends StatelessWidget {
  final String role;
  final VoidCallback onChangeRole;

  const _RoleSection({
    Key? key,
    required this.role,
    required this.onChangeRole,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Роль в проекте',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
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
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getRoleDisplayName(role),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
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
                        onTap: onChangeRole,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Сменить роль',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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

class _RemoveMemberButton extends StatelessWidget {
  final VoidCallback onRemove;

  const _RemoveMemberButton({
    Key? key,
    required this.onRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
          onTap: onRemove,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_remove,
                  color: Colors.red,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Выгнать из проекта',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}