import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:it_planner/dto/project/project_member_response.dart';
import 'package:it_planner/dto/task/task_detail_response.dart';
import 'package:it_planner/service/project_member_service.dart';
import 'package:it_planner/service/task_service.dart';
import '../theme/colors.dart';

class AssignTaskDialog {
  static void showDesktopDialog({
    required BuildContext context,
    required int projectId,
    required int taskId,
    required Assignee currentAssignedTo,
    required Function(TaskDetailResponse) onAssigned,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _DesktopAssignDialog(
          projectId: projectId,
          taskId: taskId,
          currentAssignedTo: currentAssignedTo,
          onAssigned: onAssigned,
        );
      },
    );
  }

  static void showMobileDialog({
    required BuildContext context,
    required int projectId,
    required int taskId,
    required Assignee currentAssignedTo,
    required Function(TaskDetailResponse) onAssigned,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _MobileAssignDialog(
          projectId: projectId,
          taskId: taskId,
          currentAssignedTo: currentAssignedTo,
          onAssigned: onAssigned,
        );
      },
    );
  }
}

class _DesktopAssignDialog extends StatefulWidget {
  final int projectId;
  final int taskId;
  final Assignee currentAssignedTo;
  final Function(TaskDetailResponse) onAssigned;

  const _DesktopAssignDialog({
    Key? key,
    required this.projectId,
    required this.taskId,
    required this.currentAssignedTo,
    required this.onAssigned,
  }) : super(key: key);

  @override
  _DesktopAssignDialogState createState() => _DesktopAssignDialogState();
}

class _DesktopAssignDialogState extends State<_DesktopAssignDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  List<ProjectMemberResponse> _members = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  int? _selectedMemberId;
  Map<int, String> _memberFullNames = {};
  Map<int, String?> _memberProfileImages = {};

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _loadMembers();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadMembers() async {
    try {
      final projectMemberService = ProjectMemberService();
      final members = await projectMemberService.getProjectMembers(widget.projectId);
      
      // Создаем мапы для быстрого доступа к данным пользователя
      final fullNames = <int, String>{};
      final profileImages = <int, String?>{};
      
      for (var member in members) {
        fullNames[member.id] = member.user.fullName;
        profileImages[member.id] = member.user.profileImage;
      }
      
      setState(() {
        _members = members;
        _memberFullNames = fullNames;
        _memberProfileImages = profileImages;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки участников: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки участников: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignTask() async {
    if (_selectedMemberId == null) return;
    
    setState(() {
      _isAssigning = true;
    });

    try {
      await TaskService.assignTask(
        projectId: widget.projectId,
        taskId: widget.taskId,
        employeeId: _selectedMemberId!,
      );

      // Обновляем задачу
      final taskDetails = await TaskService.getTaskDetails(widget.taskId);
      widget.onAssigned(taskDetails);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Задача успешно назначена'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Ошибка назначения задачи: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка назначения задачи: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  void _closeDialog() {
    _animationController.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Widget _buildAvatar(int userId) {
    final profileImage = _memberProfileImages[userId];
    
    if (profileImage != null && profileImage.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(profileImage),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _defaultAvatar();
            },
          ),
        );
      } catch (e) {
        return _defaultAvatar();
      }
    }
    
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Dialog(
          insetPadding: const EdgeInsets.all(20),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Заголовок
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Назначить задачу',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: AppColors.textHint,
                          size: 20,
                        ),
                        onPressed: _closeDialog,
                        splashRadius: 20,
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Список участников
                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_members.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Нет участников в проекте',
                          style: TextStyle(
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: Column(
                          children: _members.map((member) {
                            final isSelected = _selectedMemberId == member.id;
                            final fullName = _memberFullNames[member.id] ?? 'Неизвестный пользователь';
                            
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedMemberId = member.id;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.transparent,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: AppColors.cardBorder.withOpacity(0.5),
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      // Аватар
                                      _buildAvatar(member.id),
                                      const SizedBox(width: 12),
                                      
                                      // Имя
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              fullName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: AppColors.textPrimary,
                                                fontWeight: isSelected 
                                                    ? FontWeight.bold 
                                                    : FontWeight.normal,
                                              ),
                                            ),
                                            if (member.projectRole.isNotEmpty)
                                              Text(
                                                member.projectRole,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.textHint,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Чекбокс выбора
                                      if (isSelected)
                                        Icon(
                                          Icons.check_circle,
                                          color: AppColors.primary,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Кнопки
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(
                                color: AppColors.shadowLight,
                                offset: Offset(0, 2),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _closeDialog,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'Отмена',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _selectedMemberId != null
                                    ? AppColors.primary.withOpacity(0.3)
                                    : Colors.grey.withOpacity(0.3),
                                offset: const Offset(0, 4),
                                blurRadius: 8,
                                spreadRadius: -2,
                              ),
                            ],
                          ),
                          child: Material(
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: _selectedMemberId != null && !_isAssigning
                                  ? _assignTask
                                  : null,
                              child: Container(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: _selectedMemberId != null
                                      ? AppColors.primary
                                      : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: _isAssigning
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white),
                                          ),
                                        )
                                      : Text(
                                          'Назначить',
                                          style: TextStyle(
                                            color: _selectedMemberId != null
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Мобильная версия
class _MobileAssignDialog extends StatefulWidget {
  final int projectId;
  final int taskId;
  final Assignee currentAssignedTo;
  final Function(TaskDetailResponse) onAssigned;

  const _MobileAssignDialog({
    Key? key,
    required this.projectId,
    required this.taskId,
    required this.currentAssignedTo,
    required this.onAssigned,
  }) : super(key: key);

  @override
  _MobileAssignDialogState createState() => _MobileAssignDialogState();
}

class _MobileAssignDialogState extends State<_MobileAssignDialog> {
  List<ProjectMemberResponse> _members = [];
  bool _isLoading = true;
  bool _isAssigning = false;
  int? _selectedMemberId;
  Map<int, String> _memberFullNames = {};
  Map<int, String?> _memberProfileImages = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final projectMemberService = ProjectMemberService();
      final members = await projectMemberService.getProjectMembers(widget.projectId);
      
      // Создаем мапы для быстрого доступа к данным пользователя
      final fullNames = <int, String>{};
      final profileImages = <int, String?>{};
      
      for (var member in members) {
        fullNames[member.id] = member.user.fullName;
        profileImages[member.id] = member.user.profileImage;
      }
      
      setState(() {
        _members = members;
        _memberFullNames = fullNames;
        _memberProfileImages = profileImages;
        _isLoading = false;
      });
    } catch (e) {
      print('Ошибка загрузки участников: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка загрузки участников: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _assignTask() async {
    if (_selectedMemberId == null) return;
    
    setState(() {
      _isAssigning = true;
    });

    try {
      await TaskService.assignTask(
        projectId: widget.projectId,
        taskId: widget.taskId,
        employeeId: _selectedMemberId!,
      );

      // Обновляем задачу
      final taskDetails = await TaskService.getTaskDetails(widget.taskId);
      widget.onAssigned(taskDetails);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Задача успешно назначена'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('Ошибка назначения задачи: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка назначения задачи: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAssigning = false;
        });
      }
    }
  }

  Widget _buildAvatar(int userId) {
    final profileImage = _memberProfileImages[userId];
    
    if (profileImage != null && profileImage.isNotEmpty) {
      try {
        return ClipOval(
          child: Image.memory(
            base64Decode(profileImage),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _defaultAvatar();
            },
          ),
        );
      } catch (e) {
        return _defaultAvatar();
      }
    }
    
    return _defaultAvatar();
  }

  Widget _defaultAvatar() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Назначить задачу',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Список участников
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'Нет участников в проекте',
                  style: TextStyle(
                    color: AppColors.textHint,
                  ),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: _members.map((member) {
                    final isSelected = _selectedMemberId == member.id;
                    final fullName = _memberFullNames[member.id] ?? 'Неизвестный пользователь';
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedMemberId = member.id;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withOpacity(0.1)
                                : Colors.transparent,
                            border: Border(
                              bottom: BorderSide(
                                color: AppColors.cardBorder.withOpacity(0.5),
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              // Аватар
                              _buildAvatar(member.id),
                              const SizedBox(width: 12),
                              
                              // Имя
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      fullName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColors.textPrimary,
                                        fontWeight: isSelected 
                                            ? FontWeight.bold 
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    if (member.projectRole.isNotEmpty)
                                      Text(
                                        member.projectRole,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textHint,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Чекбокс выбора
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Кнопки
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedMemberId != null && !_isAssigning
                      ? _assignTask
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isAssigning
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white),
                          ),
                        )
                      : const Text('Назначить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}