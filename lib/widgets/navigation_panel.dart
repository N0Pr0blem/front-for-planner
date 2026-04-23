import 'package:flutter/material.dart';
import '../theme/colors.dart';

class NavigationPanel extends StatelessWidget {
  final VoidCallback onTasksTap;
  final VoidCallback onMembersTap;
  final VoidCallback onRepositoryTap;
  final bool isTasksActive;
  final bool isMembersActive;
  final bool isRepositoryActive;
  final bool showArchive; // Новый параметр
  final bool isArchiveActive; // Новый параметр
  final VoidCallback? onArchiveTap; // Новый параметр

  const NavigationPanel({
    Key? key,
    required this.onTasksTap,
    required this.onMembersTap,
    required this.onRepositoryTap,
    required this.isTasksActive,
    required this.isMembersActive,
    required this.isRepositoryActive,
    this.showArchive = false,
    this.isArchiveActive = false,
    this.onArchiveTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.third_background,
      child: Column(
        children: [
          const SizedBox(height: 20, width: 20),
          _NavigationButton(
            icon: Icons.task,
            label: 'Задачи',
            isActive: isTasksActive,
            onTap: onTasksTap,
          ),
          if (showArchive) ...[
            _NavigationButton(
              icon: Icons.archive,
              label: 'Архив',
              isActive: isArchiveActive,
              onTap: onArchiveTap ?? () {},
            ),
          ],
          _NavigationButton(
            icon: Icons.people,
            label: 'Участники',
            isActive: isMembersActive,
            onTap: onMembersTap,
          ),
          _NavigationButton(
            icon: Icons.folder,
            label: 'Файлы',
            isActive: isRepositoryActive,
            onTap: onRepositoryTap,
          ),
          const Spacer(),
          _NavigationButton(
            icon: Icons.settings,
            label: 'Настройки',
            isActive: false,
            onTap: () {},
          ),
          const SizedBox(height: 20, width: 20),
        ],
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavigationButton({
    Key? key,
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      height: 70,
      width: 70,
      decoration: BoxDecoration(
        color:
            isActive ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color:
                      isActive ? AppColors.textOnPrimary : AppColors.textHint,
                  size: 24,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isActive ? AppColors.textOnPrimary : AppColors.textHint,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
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
