import 'package:flutter/material.dart';
import 'package:it_planner/theme/colors.dart';

class PaginationButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const PaginationButton({
    Key? key,
    required this.icon,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 20),
      onPressed: onPressed,
      color: onPressed != null ? Colors.orange : AppColors.textHint,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
    );
  }
}