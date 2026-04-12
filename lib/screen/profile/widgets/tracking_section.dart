// lib/screen/profile/widgets/tracking_section.dart

import 'package:flutter/material.dart';
import '../../../dto/tracking/user_tracking_response.dart';
import '../../../theme/colors.dart';

class TrackingSection extends StatelessWidget {
  final UserTrackingResponse trackingData;

  const TrackingSection({
    Key? key,
    required this.trackingData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight.withOpacity(0.5),
            offset: const Offset(0, 8),
            blurRadius: 20,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Фиксированный заголовок
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppGradients.primaryButton,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Учёт рабочего времени',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Всего: ${trackingData.hourSum.toStringAsFixed(1)} ${_getHoursWord(trackingData.hourSum)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (trackingData.trekkingList.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildWeeklyStats(),
                ],
              ],
            ),
          ),
          // Растягивающийся контент
          Expanded(
            child: trackingData.trekkingList.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: _EmptyState(
                      icon: Icons.timer_off,
                      message: 'Нет данных об учёте времени',
                    ),
                  )
                : _buildTrackingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyStats() {
    final sortedDates = trackingData.hoursByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final recentDates = sortedDates.take(7).toList();

    // Находим максимальное значение часов
    double maxHours = 0.0;
    for (var hours in trackingData.hoursByDate.values) {
      if (hours > maxHours) maxHours = hours;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Последние 7 дней',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentDates.length,
            itemBuilder: (context, index) {
              final date = recentDates[index];
              final double hours = trackingData.hoursByDate[date] ?? 0.0;
              final double barHeight =
                  maxHours > 0 ? (hours / maxHours * 60) : 0.0;

              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    Text(
                      hours.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Container(
                        width: 30,
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: barHeight > 0
                              ? barHeight
                              : 2.0, // Теперь barHeight точно double
                          decoration: BoxDecoration(
                            gradient: AppGradients.primaryButton,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDateShort(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                    Text(
                      _getDayOfWeek(date),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textHint.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingList() {
    final groupedData = trackingData.groupedByDate;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      itemCount: groupedData.keys.length,
      itemBuilder: (context, index) {
        final date = groupedData.keys.elementAt(index);
        final items = groupedData[date]!;
        final dayTotal = trackingData.hoursByDate[date] ?? 0;

        return _DateGroup(
          date: date,
          items: items,
          dayTotal: dayTotal,
        );
      },
    );
  }

  String _getHoursWord(double hours) {
    if (hours % 10 == 1 && hours % 100 != 11) return 'час';
    if ([2, 3, 4].contains(hours % 10) && ![12, 13, 14].contains(hours % 100)) {
      return 'часа';
    }
    return 'часов';
  }

  String _getDayOfWeek(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length != 3) return '';
    final date =
        DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[date.weekday - 1];
  }

  String _formatDateShort(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}';
    }
    return dateStr;
  }
}

class _DateGroup extends StatelessWidget {
  final String date;
  final List<TrackingItem> items;
  final double dayTotal;

  const _DateGroup({
    required this.date,
    required this.items,
    required this.dayTotal,
  });

  String _formatDate(String dateStr) {
    final parts = dateStr.split('-');
    if (parts.length == 3) {
      final date = DateTime(
          int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      const months = [
        'января',
        'февраля',
        'марта',
        'апреля',
        'мая',
        'июня',
        'июля',
        'августа',
        'сентября',
        'октября',
        'ноября',
        'декабря'
      ];
      const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
      return '${parts[2]} ${months[date.month - 1]} ${parts[0]}, ${days[date.weekday - 1]}';
    }
    return dateStr;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок дня
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _formatDate(date),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${dayTotal.toStringAsFixed(1)} ч',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Список записей за день
          ...items.map((item) => _TrackingItemCard(item: item)).toList(),
        ],
      ),
    );
  }
}

class _TrackingItemCard extends StatelessWidget {
  final TrackingItem item;

  const _TrackingItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8, left: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder.withOpacity(0.3)),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowLight,
            offset: Offset(0, 2),
            blurRadius: 4,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Задача #${item.taskDetailsId}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.employeeName,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${item.hours.toStringAsFixed(1)} ч',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cardBorder.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 48,
            color: AppColors.textHint.withOpacity(0.5),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
