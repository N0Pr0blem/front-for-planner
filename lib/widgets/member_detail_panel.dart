// member_detail_panel.dart (исправленная версия)
import 'package:flutter/material.dart';
import '../dto/project/project_member_response.dart';
import '../theme/colors.dart';
import '../service/project_member_service.dart';
import 'dart:convert';
import 'change_role_dialog.dart';

class MemberDetailPanel extends StatefulWidget {
  final ProjectMemberResponse member;
  final int projectId;
  final VoidCallback onMemberUpdated;
  final VoidCallback onMemberRemoved;
  final VoidCallback onClose;
  final bool isMobile;

  const MemberDetailPanel({
    Key? key,
    required this.member,
    required this.projectId,
    required this.onMemberUpdated,
    required this.onMemberRemoved,
    required this.onClose,
    this.isMobile = false,
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
          title: const Text('Выгнать участника'),
          content: Text('Вы уверены, что хотите выгнать ${widget.member.user.fullName} из проекта?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _removeMember();
              },
              child: const Text(
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
        const SnackBar(
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
    if (widget.isMobile) {
      // Мобильная версия - Bottom Sheet
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
            child: ChangeRoleDialog(
              currentRole: widget.member.projectRole,
              projectId: widget.projectId,
              memberId: widget.member.id,
              onRoleChanged: () {
                widget.onMemberUpdated();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Роль обновлена'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          );
        },
      );
    } else {
      // Десктоп версия - Dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangeRoleDialog(
            currentRole: widget.member.projectRole,
            projectId: widget.projectId,
            memberId: widget.member.id,
            onRoleChanged: () {
              widget.onMemberUpdated();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Роль обновлена'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.user.fullName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onClose,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              _showMobileActionMenu(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Аватар и имя
            _buildMobileAvatarSection(),
            
            const SizedBox(height: 32),
            
            // Роль
            _buildMobileRoleSection(),
            
            const SizedBox(height: 32),
            
            // Информация о пользователе
            _buildUserInfoSection(),
            
            const SizedBox(height: 32),
            
            // Кнопка выгона
            _buildMobileRemoveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileAvatarSection() {
    final user = widget.member.user;
    
    return Center(
      child: Column(
        children: [
          // Аватар
          if (user.hasAvatar && user.profileImage != null)
            ClipOval(
              child: Image.memory(
                base64Decode(user.profileImage!),
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
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ID участника
          Text(
            'ID: ${widget.member.id}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRoleSection() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary.withOpacity(0.05),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Роль в проекте',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _getRoleDisplayName(widget.member.projectRole),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: AppColors.primary,
            ),
            onPressed: _showChangeRoleDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    final user = widget.member.user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Имя
        if (user.firstName != null && user.firstName!.isNotEmpty)
          _buildInfoItem('Имя', user.firstName!),
        
        // Фамилия
        if (user.lastName != null && user.lastName!.isNotEmpty)
          _buildInfoItem('Фамилия', user.lastName!),
        
        // Отчество
        if (user.secondName != null && user.secondName!.isNotEmpty)
          _buildInfoItem('Отчество', user.secondName!),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileRemoveButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _showRemoveConfirmationDialog,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
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
                              widget.member.user.fullName,
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
                          _buildDesktopAvatarSection(),
                          
                          const SizedBox(height: 24),

                          // Роль
                          _buildDesktopRoleSection(),

                          const SizedBox(height: 32),

                          // Информация о пользователе
                          _buildDesktopUserInfo(),

                          const SizedBox(height: 32),

                          // Кнопка выгона
                          _buildDesktopRemoveButton(),
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

  Widget _buildDesktopAvatarSection() {
    final user = widget.member.user;
    
    return Center(
      child: Column(
        children: [
          // Аватар
          if (user.hasAvatar && user.profileImage != null)
            ClipOval(
              child: Image.memory(
                base64Decode(user.profileImage!),
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
            user.fullName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // ID участника
          Text(
            'ID: ${widget.member.id}',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRoleSection() {
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
                    _getRoleDisplayName(widget.member.projectRole),
                    style: const TextStyle(
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
                        onTap: _showChangeRoleDialog,
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
                              const Text(
                                'Сменить роль',
                                style: TextStyle(
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

  Widget _buildDesktopUserInfo() {
    final user = widget.member.user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Информация',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        
        if (user.firstName != null && user.firstName!.isNotEmpty)
          _buildDesktopInfoItem('Имя', user.firstName!),
        
        if (user.lastName != null && user.lastName!.isNotEmpty)
          _buildDesktopInfoItem('Фамилия', user.lastName!),
        
        if (user.secondName != null && user.secondName!.isNotEmpty)
          _buildDesktopInfoItem('Отчество', user.secondName!),
      ],
    );
  }

  Widget _buildDesktopInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRemoveButton() {
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
          onTap: _showRemoveConfirmationDialog,
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

  void _showMobileActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppColors.primary),
              title: const Text('Сменить роль'),
              onTap: () {
                Navigator.pop(context);
                _showChangeRoleDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: const Text('Выгнать из проекта'),
              onTap: () {
                Navigator.pop(context);
                _showRemoveConfirmationDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Отмена'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        );
      },
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