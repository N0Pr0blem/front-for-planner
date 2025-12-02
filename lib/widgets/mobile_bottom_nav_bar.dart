import 'package:flutter/material.dart';
import '../theme/colors.dart';

class MobileBottomNavBar extends StatelessWidget {
  final VoidCallback onTasksTap;
  final VoidCallback onMembersTap;
  final VoidCallback onRepositoryTap;
  final VoidCallback onProfileTap;
  final VoidCallback onSettingsTap;
  final bool isTasksActive;
  final bool isMembersActive;
  final bool isRepositoryActive;

  const MobileBottomNavBar({
    Key? key,
    required this.onTasksTap,
    required this.onMembersTap,
    required this.onRepositoryTap,
    required this.onProfileTap,
    required this.onSettingsTap,
    required this.isTasksActive,
    required this.isMembersActive,
    required this.isRepositoryActive,
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
            _NavIconButton(
              icon: Icons.person,
              label: 'Профиль',
              isActive: false,
              onTap: onProfileTap,
            ),
            _NavIconButton(
              icon: Icons.settings,
              label: 'Настройки',
              isActive: false,
              onTap: onSettingsTap,
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
                  size: 24,
                  color: isActive 
                    ? AppColors.primary 
                    : AppColors.textHint,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
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