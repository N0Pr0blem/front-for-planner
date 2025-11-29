class TrekkingResponse {
  final List<TrekkingEntry> trekkingList;
  final double hourSum;

  TrekkingResponse({
    required this.trekkingList,
    required this.hourSum,
  });

  factory TrekkingResponse.fromJson(Map<String, dynamic> json) {
    final list = json['trekking_list'] as List;
    return TrekkingResponse(
      trekkingList: list.map((e) => TrekkingEntry.fromJson(e as Map<String, dynamic>)).toList(),
      hourSum: (json['hour_sum'] as num).toDouble(),
    );
  }
}

class TrekkingEntry {
  final int id;
  final String date;
  final double hours;
  final String employeeFirstName;
  final String employeeSecondName;
  final int taskDetailsId;

  TrekkingEntry({
    required this.id,
    required this.date,
    required this.hours,
    required this.employeeFirstName,
    required this.employeeSecondName,
    required this.taskDetailsId,
  });

  factory TrekkingEntry.fromJson(Map<String, dynamic> json) {
    return TrekkingEntry(
      id: json['id'] as int,
      date: json['date'] as String,
      hours: (json['hours'] as num).toDouble(),
      employeeFirstName: json['employee_first_name'] as String,
      employeeSecondName: json['employee_second_name'] as String,
      taskDetailsId: json['task_details_id'] as int,
    );
  }
}