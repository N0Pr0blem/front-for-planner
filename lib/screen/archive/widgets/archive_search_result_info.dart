import 'package:flutter/material.dart';
import 'package:it_planner/theme/colors.dart';

class ArchiveSearchResultInfo extends StatelessWidget {
  final int filteredCount;
  final int totalCount;

  const ArchiveSearchResultInfo({
    Key? key,
    required this.filteredCount,
    required this.totalCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'Найдено: $filteredCount из $totalCount',
        style: TextStyle(fontSize: 11, color: AppColors.textHint),
      ),
    );
  }
}