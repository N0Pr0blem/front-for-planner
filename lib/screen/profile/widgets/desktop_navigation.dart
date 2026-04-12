// lib/screen/profile/widgets/desktop_navigation.dart
import 'package:flutter/material.dart';
import '../../../theme/colors.dart';

class DesktopNavigation extends StatelessWidget {
  final String activeSection;
  final Function(String) onSectionChanged;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const DesktopNavigation({
    Key? key,
    required this.activeSection,
    required this.onSectionChanged,
    required this.onBack,
    required this.onLogout,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.third_background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          _NavButton(
            icon: Icons.arrow_back,
            label: 'Назад к задачам',
            onTap: onBack,
          ),
          const SizedBox(height: 32),
          _NavButton(
            icon: Icons.person,
            label: 'Профиль',
            isActive: activeSection == 'profile',
            onTap: () => onSectionChanged('profile'),
          ),
          _NavButton(
            icon: Icons.folder,
            label: 'Мои проекты',
            isActive: activeSection == 'projects',
            onTap: () => onSectionChanged('projects'),
          ),
          _NavButton(
            icon: Icons.task,
            label: 'Мои задачи',
            isActive: activeSection == 'tasks',
            onTap: () => onSectionChanged('tasks'),
          ),
          _NavButton(
            icon: Icons.timer, // Новая кнопка
            label: 'Учёт времени',
            isActive: activeSection == 'tracking',
            onTap: () => onSectionChanged('tracking'),
          ),
          _NavButton(
            icon: Icons.auto_awesome,
            label: 'Ответы ИИ',
            isActive: activeSection == 'ai',
            onTap: () => onSectionChanged('ai'),
          ),
          const Spacer(),
          _NavButton(
            icon: Icons.logout,
            label: 'Выйти',
            onTap: onLogout,
            isLogout: true,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final bool isLogout;

  const _NavButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 4),
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
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isLogout
                      ? Colors.red
                      : (isActive
                          ? AppColors.textOnPrimary
                          : AppColors.textHint),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isLogout
                        ? Colors.red
                        : (isActive
                            ? AppColors.textOnPrimary
                            : AppColors.textHint),
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
