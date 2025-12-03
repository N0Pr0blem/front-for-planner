class TaskDetailResponse {
  final int id;
  final String name;
  final bool isCompleted;
  final String? status;
  final String priority;
  final String complexity;
  final String description;
  final List<String> documents;
  final DateTime creationDate;
  final Assignee assignedBy;
  final Assignee assignedTo;
  final int projectId;

  TaskDetailResponse(
      {required this.id,
      required this.name,
      required this.isCompleted,
      required this.status,
      required this.priority,
      required this.complexity,
      required this.description,
      required this.documents,
      required this.creationDate,
      required this.assignedBy,
      required this.assignedTo,
      required this.projectId});

  factory TaskDetailResponse.fromJson(Map<String, dynamic> json) {
    return TaskDetailResponse(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] as String?) ?? '',
      isCompleted: (json['is_completed'] as bool?) ?? false,
      status: (json['status'] as String?) ?? '',
      priority: (json['urgency'] as String?) ?? '',
      complexity: (json['complexity'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      documents: _parseDocuments(json['documents']),
      projectId: (json['project_id'] as num?)?.toInt() ?? 0,
      creationDate:
          DateTime.tryParse(json['creation_date']?.toString() ?? '') ??
              DateTime.now(),
      assignedBy: json['assigned_by'] != null
          ? Assignee.fromJson(json['assigned_by'] as Map<String, dynamic>)
          : Assignee(
              profileImage: null,
              firstName: '',
              secondName: null,
              lastName: null,
            ),
      assignedTo: json['assigned_to'] != null
          ? Assignee.fromJson(json['assigned_to'] as Map<String, dynamic>)
          : Assignee(
              profileImage: null,
              firstName: '',
              secondName: null,
              lastName: null,
            ),
    );
  }

  static List<String> _parseDocuments(dynamic documents) {
    if (documents == null) return [];
    if (documents is List) {
      return documents.whereType<String>().toList();
    }
    return [];
  }

  factory TaskDetailResponse.empty(
      {required int projectId, required Assignee currentUser}) {
    return TaskDetailResponse(
      id: 0, 
      name: '',
      isCompleted: false,
      status: 'TO_DO',
      priority: 'MEDIUM',
      complexity: 'MEDIUM',
      description: '',
      documents: [],
      creationDate: DateTime.now(),
      assignedBy: currentUser, 
      assignedTo: Assignee(
        profileImage: null,
        firstName: '',
        secondName: null,
        lastName: null,
      ),
      projectId: projectId,
    );
  }
}

class Assignee {
  final String? profileImage;
  final String firstName;
  final String? secondName;
  final String? lastName;

  Assignee({
    this.profileImage,
    required this.firstName,
    this.secondName,
    this.lastName,
  });

  String get fullName {
    final parts = [firstName, secondName, lastName]
      ..removeWhere((s) => s == null || s.isEmpty || s == 'null');

    if (parts.isEmpty) return 'Не назначено';
    if (parts.length == 1) return parts.first!;

    return parts.join(' ').trim();
  }

  bool get hasAvatar =>
      profileImage != null &&
      profileImage!.isNotEmpty &&
      profileImage != 'null';

  factory Assignee.fromJson(Map<String, dynamic> json) {
    dynamic rawImage = json['profile_image'];
    String? profileImage;
    if (rawImage == null) {
      profileImage = null;
    } else if (rawImage is String && rawImage == 'null') {
      profileImage = null;
    } else if (rawImage is String) {
      profileImage = rawImage;
    } else {
      profileImage = null;
    }

    return Assignee(
      profileImage: profileImage,
      firstName: (json['first_name'] as String?) ?? '',
      secondName: json['second_name'] as String?,
      lastName: json['last_name'] as String?,
    );
  }
}
