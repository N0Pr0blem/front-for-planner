import 'package:flutter/material.dart';
import 'package:your_app_name/dto/task/task_detail_response.dart';
import '../theme/colors.dart';
import '../dto/task/trekking_response.dart';
import 'dart:convert';
import '../service/task_service.dart'; // Добавьте импорт сервиса

class TaskInfoPanel extends StatelessWidget {
  final TaskDetailResponse? task;
  final TrekkingResponse? trekking;
  final VoidCallback? onTaskUpdated; // Добавим колбэк для обновления

  const TaskInfoPanel({
    Key? key,
    required this.task,
    this.trekking,
    this.onTaskUpdated, // Добавим опциональный колбэк
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (task == null) {
      return Container(
        color: AppColors.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _UserInfoSection(
              title: 'Создал',
              user: Assignee(
                profileImage: null,
                firstName: 'Загрузка...',
                secondName: null,
                lastName: null,
              ),
              showAssignButton: false,
            ),
            const SizedBox(height: 24),
            _UserInfoSection(
              title: 'Ответственный',
              user: Assignee(
                profileImage: null,
                firstName: 'Не назначено',
                secondName: null,
                lastName: null,
              ),
              showAssignButton: false,
            ),
            const SizedBox(height: 24),
            _TimeSpentSection(timeSpent: '0.0h'),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserInfoSection(
            title: 'Создал',
            user: task!.assignedBy,
            showAssignButton: false,
          ),
          const SizedBox(height: 24),
          _UserInfoSection(
            title: 'Ответственный',
            user: task!.assignedTo,
            showAssignButton: true,
            task: task!,
            onAssigned: onTaskUpdated,
          ),
          const SizedBox(height: 24),
          _TimeSpentSection(timeSpent: '${trekking?.hourSum ?? 0.0}h'),
        ],
      ),
    );
  }
}

class _UserInfoSection extends StatefulWidget {
  final String title;
  final Assignee user;
  final bool showAssignButton;
  final TaskDetailResponse? task;
  final VoidCallback? onAssigned;

  const _UserInfoSection({
    Key? key,
    required this.title,
    required this.user,
    required this.showAssignButton,
    this.task,
    this.onAssigned,
  }) : super(key: key);

  @override
  __UserInfoSectionState createState() => __UserInfoSectionState();
}

class __UserInfoSectionState extends State<_UserInfoSection> {
  bool _isLoading = false;

  Future<void> _assignToMe() async {
    if (widget.task == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Вызываем метод для назначения задачи на текущего пользователя
      await TaskService.assignTaskToMe(
        projectId: widget.task!.projectId, // Предполагаем, что есть projectId
        taskId: widget.task!.id,
      );

      // Уведомляем родителя об обновлении
      if (widget.onAssigned != null) {
        widget.onAssigned!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Задача назначена на вас'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
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
          _isLoading = false;
        });
      }
    }
  }

  bool get _isEmptyAssignee {
    return widget.user.firstName.isEmpty ||
        widget.user.firstName == 'Unassigned' ||
        widget.user.fullName.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (widget.showAssignButton && _isEmptyAssignee)
          _AssignToMeButton(
            onPressed: _assignToMe,
            isLoading: _isLoading,
          )
        else
          _UserCard(user: widget.user),
      ],
    );
  }
}

class _AssignToMeButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _AssignToMeButton({
    Key? key,
    required this.onPressed,
    required this.isLoading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary),
                          ),
                        )
                      : Icon(
                          Icons.person_add_alt_1,
                          color: AppColors.primary,
                          size: 24,
                        ),
                ),
                const SizedBox(height: 12),
                Text(
                  isLoading ? 'Назначаем...' : 'Назначить на себя',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Стать ответственным',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final Assignee user;

  const _UserCard({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEmptyUser =
        user.firstName.isEmpty || user.fullName == 'Не назначено';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 4),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          // Аватар
          if (user.hasAvatar)
            ClipOval(
              child: Image.memory(
                base64Decode(user.profileImage!),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isEmptyUser
                    ? AppColors.textHint.withOpacity(0.2)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isEmptyUser ? Icons.person_outline : Icons.person,
                color: isEmptyUser ? AppColors.textHint : AppColors.primary,
              ),
            ),
          const SizedBox(width: 12),
          // Имя
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isEmptyUser
                        ? AppColors.textHint
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmptyUser ? 'Не назначен' : 'Team Member',
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
    );
  }
}

class _TimeSpentSection extends StatelessWidget {
  final String timeSpent;

  const _TimeSpentSection({
    Key? key,
    required this.timeSpent,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Время',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: AppGradients.primaryButton,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: AppColors.shadowPrimary,
                offset: Offset(0, 8),
                blurRadius: 16,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.timer,
                color: AppColors.textOnPrimary,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                timeSpent,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Потраченное время',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textOnPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
