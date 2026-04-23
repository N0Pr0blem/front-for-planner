import 'package:flutter/material.dart';
import 'package:it_planner/theme/colors.dart';

class ArchiveSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final String? statusFilter;
  final List<Map<String, dynamic>> statuses;
  final ValueChanged<String?> onStatusFilterChanged;
  final String sortBy;
  final ValueChanged<String?> onSortByChanged;
  final bool sortAscending;
  final VoidCallback onSortDirectionToggle;
  final VoidCallback onReset;

  const ArchiveSearchBar({
    Key? key,
    required this.searchController,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.statusFilter,
    required this.statuses,
    required this.onStatusFilterChanged,
    required this.sortBy,
    required this.onSortByChanged,
    required this.sortAscending,
    required this.onSortDirectionToggle,
    required this.onReset,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Icon(Icons.search, color: AppColors.textHint, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Поиск в архиве',
                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textHint),
                      suffixIcon: searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear, color: AppColors.textHint, size: 18),
                              onPressed: () {
                                searchController.clear();
                                onSearchChanged('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.cardBorder.withOpacity(0.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String?>(
              value: statusFilter,
              hint: Row(
                children: [
                  Icon(Icons.filter_list, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Статус', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                ],
              ),
              underline: const SizedBox(),
              items: statuses.map((status) {
                return DropdownMenuItem<String?>(
                  value: status['value'],
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: status['color'],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(status['label'], style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onStatusFilterChanged,
            ),
          ),
          Container(width: 1, height: 28, color: AppColors.cardBorder.withOpacity(0.5)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButton<String>(
              value: sortBy,
              hint: Row(
                children: [
                  Icon(Icons.sort, size: 18, color: AppColors.textHint),
                  const SizedBox(width: 6),
                  Text('Сорт.', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                ],
              ),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'name', child: Text('По названию', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'status', child: Text('По статусу', style: TextStyle(fontSize: 13))),
                DropdownMenuItem(value: 'assignee', child: Text('По исполнителю', style: TextStyle(fontSize: 13))),
              ],
              onChanged: onSortByChanged,
            ),
          ),
          IconButton(
            onPressed: onSortDirectionToggle,
            icon: Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: Colors.orange,
            ),
          ),
          if (statusFilter != null || searchQuery.isNotEmpty)
            TextButton(
              onPressed: onReset,
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
              child: Text(
                'Сбросить',
                style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}