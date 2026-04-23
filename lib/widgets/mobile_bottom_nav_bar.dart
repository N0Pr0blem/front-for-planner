import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MobileBottomNavBar extends StatelessWidget {
  final VoidCallback onTasksTap;
  final VoidCallback onMembersTap;
  final VoidCallback onRepositoryTap;
  final VoidCallback onArchiveTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final bool isTasksActive;
  final bool isMembersActive;
  final bool isRepositoryActive;
  final bool isArchiveActive;

  const MobileBottomNavBar({
    Key? key,
    required this.onTasksTap,
    required this.onMembersTap,
    required this.onRepositoryTap,
    required this.onArchiveTap,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.isTasksActive,
    required this.isMembersActive,
    required this.isRepositoryActive,
    this.isArchiveActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: AppColors.cardBorder.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavIconButton(
              icon: Icons.task,
              label: 'Задачи',
              isActive: isTasksActive,
              onTap: onTasksTap,
            ),
            _NavIconButton(
              icon: Icons.archive,
              label: 'Архив',
              isActive: isArchiveActive,
              onTap: onArchiveTap,
            ),
            _NavIconButton(
              icon: Icons.people,
              label: 'Участники',
              isActive: isMembersActive,
              onTap: onMembersTap,
            ),
            _NavIconButton(
              icon: Icons.folder,
              label: 'Репозиторий',
              isActive: isRepositoryActive,
              onTap: onRepositoryTap,
            ),
            // Меню с дополнительными опциями
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_horiz,
                color: AppColors.textHint,
                size: 24,
              ),
              offset: const Offset(0, -50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              onSelected: (value) {
                if (value == 'profile') {
                  onProfileTap();
                } else if (value == 'settings') {
                  onSettingsTap();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      Icon(Icons.person, size: 20),
                      SizedBox(width: 12),
                      Text('Профиль'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20),
                      SizedBox(width: 12),
                      Text('Настройки'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavIconButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22, // Чуть уменьшил размер
                  color: isActive 
                    ? AppColors.primary 
                    : AppColors.textHint,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 9, // Уменьшил шрифт чтобы поместилось
                    color: isActive 
                      ? AppColors.primary 
                      : AppColors.textHint,
                    fontWeight: isActive 
                      ? FontWeight.w600 
                      : FontWeight.normal,
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