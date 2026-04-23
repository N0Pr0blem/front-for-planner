import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:it_planner/dto/task/task_response.dart';
import 'package:it_planner/theme/colors.dart';

class ArchiveTaskCard extends StatelessWidget {
  final TaskResponse task;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRestore;
  final String Function(String) getStatusText;
  final Color Function(String) getStatusColor;
  final String Function(TaskResponse) getAssigneeText;
  final Widget Function(String, {double size}) buildStatusIcon;

  const ArchiveTaskCard({
    Key? key,
    required this.task,
    required this.isSelected,
    required this.onTap,
    required this.onRestore,
    required this.getStatusText,
    required this.getStatusColor,
    required this.getAssigneeText,
    required this.buildStatusIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final assigneeText = getAssigneeText(task);
    final hasAssignee = task.assignBy.isNotEmpty && task.assignBy != 'null null';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? Colors.orange : AppColors.cardBorder.withOpacity(0.5),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                buildStatusIcon(task.status!, size: 22),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: isSelected ? Colors.orange : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (hasAssignee) ...[
                            if (task.assignByImage != null && task.assignByImage!.isNotEmpty)
                              Container(
                                width: 18,
                                height: 18,
                                margin: const EdgeInsets.only(right: 6),
                                child: ClipOval(
                                  child: Image.memory(
                                    base64Decode(task.assignByImage!),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(Icons.person, size: 18, color: AppColors.textHint);
                                    },
                                  ),
                                ),
                              )
                            else
                              Icon(Icons.person, size: 16, color: AppColors.textHint),
                            const SizedBox(width: 4),
                            Text(
                              assigneeText,
                              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppColors.textHint.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            getStatusText(task.status!),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: getStatusColor(task.status!),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: 'Восстановить из архива',
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onRestore,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.unarchive,
                          size: 20,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 12),
                  Icon(Icons.check_circle, color: Colors.orange, size: 22),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}