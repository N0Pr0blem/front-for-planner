import 'package:flutter/material.dart';
import 'package:it_planner/screen/archive/widgets/pagination_button.dart';
import 'package:it_planner/theme/colors.dart';

class ArchivePaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  const ArchivePaginationBar({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PaginationButton(
            icon: Icons.first_page,
            onPressed: currentPage > 0 ? () => onPageChanged(0) : null,
          ),
          PaginationButton(
            icon: Icons.chevron_left,
            onPressed: currentPage > 0 ? () => onPageChanged(currentPage - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Страница ${currentPage + 1} из $totalPages',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          PaginationButton(
            icon: Icons.chevron_right,
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(currentPage + 1) : null,
          ),
          PaginationButton(
            icon: Icons.last_page,
            onPressed: currentPage < totalPages - 1 ? () => onPageChanged(totalPages - 1) : null,
          ),
        ],
      ),
    );
  }
}