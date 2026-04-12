// lib/dto/tracking/user_tracking_response.dart

class UserTrackingResponse {
  final List<TrackingItem> trekkingList;
  final double hourSum;

  UserTrackingResponse({
    required this.trekkingList,
    required this.hourSum,
  });

  factory UserTrackingResponse.fromJson(Map<String, dynamic> json) {
    return UserTrackingResponse(
      trekkingList: (json['trekking_list'] as List)
          .map((item) => TrackingItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      hourSum: (json['hour_sum'] as num).toDouble(),
    );
  }

  // Группировка по датам для удобного отображения
  Map<String, List<TrackingItem>> get groupedByDate {
    final Map<String, List<TrackingItem>> grouped = {};
    for (var item in trekkingList) {
      if (!grouped.containsKey(item.date)) {
        grouped[item.date] = [];
      }
      grouped[item.date]!.add(item);
    }
    // Сортируем даты от новых к старым
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (var key in sortedKeys) key: grouped[key]!};
  }

  // Сумма часов по дням
  Map<String, double> get hoursByDate {
    final Map<String, double> hours = {};
    for (var item in trekkingList) {
      hours[item.date] = (hours[item.date] ?? 0) + item.hours;
    }
    return hours;
  }
}

class TrackingItem {
  final int id;
  final String date;
  final double hours;
  final String employeeFirstName;
  final String employeeSecondName;
  final int taskDetailsId;
  final String taskName;

  TrackingItem({
    required this.id,
    required this.date,
    required this.hours,
    required this.employeeFirstName,
    required this.employeeSecondName,
    required this.taskDetailsId,
    required this.taskName,
  });

  factory TrackingItem.fromJson(Map<String, dynamic> json) {
    return TrackingItem(
      id: json['id'] as int,
      date: json['date'] as String,
      hours: (json['hours'] as num).toDouble(),
      employeeFirstName: json['employee_first_name'] as String,
      employeeSecondName: json['employee_second_name'] as String,
      taskDetailsId: json['task_details_id'] as int,
      taskName: json['task_name'] as String,
    );
  }

  String get formattedDate {
    final parts = date.split('-');
    if (parts.length == 3) {
      return '${parts[2]}.${parts[1]}.${parts[0]}';
    }
    return date;
  }

  String get employeeName => '$employeeFirstName $employeeSecondName';
}