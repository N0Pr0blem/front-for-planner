import 'package:flutter/material.dart';
import 'package:it_planner/theme/colors.dart';

class ArchiveEmptyState extends StatelessWidget {
  final bool hasSearch;

  const ArchiveEmptyState({
    Key? key,
    required this.hasSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.archive_outlined,
            size: 64,
            color: Colors.orange.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            hasSearch ? 'Ничего не найдено' : 'Архив пуст',
            style: TextStyle(
              color: AppColors.textHint,
              fontSize: 16,
            ),
          ),
          if (!hasSearch) ...[
            const SizedBox(height: 8),
            Text(
              'Архивированные задачи появятся здесь',
              style: TextStyle(
                color: AppColors.textHint.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}