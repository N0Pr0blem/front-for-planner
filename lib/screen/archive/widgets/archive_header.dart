import 'package:flutter/material.dart';
import 'package:it_planner/screen/archive/widgets/page_indicator.dart';
import 'package:it_planner/theme/colors.dart';

class ArchiveHeader extends StatelessWidget {
  final int taskCount;
  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  const ArchiveHeader({
    Key? key,
    required this.taskCount,
    required this.totalPages,
    required this.currentPage,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.archive, color: Colors.orange, size: 24),
            const SizedBox(width: 8),
            Text(
              'Архив задач',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$taskCount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ),
          ],
        ),
        if (totalPages > 1)
          PageIndicator(
            currentPage: currentPage,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
          ),
      ],
    );
  }
}
