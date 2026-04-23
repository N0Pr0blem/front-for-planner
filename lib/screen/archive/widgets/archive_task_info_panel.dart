// lib/screen/archive/widgets/archive_task_info_panel.dart
import 'package:flutter/material.dart';
import 'package:it_planner/dto/task/task_detail_response.dart';
import 'package:it_planner/theme/colors.dart';
import 'dart:convert';

class ArchiveTaskInfoPanel extends StatelessWidget {
  final TaskDetailResponse task;

  const ArchiveTaskInfoPanel({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _UserInfoSection(
            title: 'Создал',
            user: task.assignedBy,
          ),
          const SizedBox(height: 24),
          _UserInfoSection(
            title: 'Ответственный',
            user: task.assignedTo,
          ),
          const SizedBox(height: 24),
          _ArchiveBadge(),
        ],
      ),
    );
  }
}

class _UserInfoSection extends StatelessWidget {
  final String title;
  final Assignee user;

  const _UserInfoSection({
    Key? key,
    required this.title,
    required this.user,
  }) : super(key: key);

  bool get _isEmptyAssignee {
    return user.firstName.isEmpty ||
        user.firstName == 'Unassigned' ||
        user.fullName.trim().isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
                    color: _isEmptyAssignee
                        ? AppColors.textHint.withOpacity(0.2)
                        : AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isEmptyAssignee ? Icons.person_outline : Icons.person,
                    color: _isEmptyAssignee ? AppColors.textHint : AppColors.primary,
                  ),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _isEmptyAssignee ? AppColors.textHint : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEmptyAssignee ? 'Не назначен' : 'Team Member',
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
      ],
    );
  }
}

class _ArchiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange.withOpacity(0.8),
            Colors.deepOrange.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            offset: const Offset(0, 8),
            blurRadius: 16,
            spreadRadius: -8,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.archive,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 8),
          const Text(
            'В архиве',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Задача находится в архиве',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}