class ProjectMemberResponse {
  final int id;
  final String projectRole;
  final UserInfoForTaskDto user;

  ProjectMemberResponse({
    required this.id,
    required this.projectRole,
    required this.user,
  });

  factory ProjectMemberResponse.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing ProjectMemberResponse: $json');
    
    return ProjectMemberResponse(
      id: _safeParseInt(json['id']),
      projectRole: _safeParseString(json['project_role']) ?? 'ANOTHER',
      user: UserInfoForTaskDto.fromJson(json['user'] ?? {}),
    );
  }

  static int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _safeParseString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    return value.toString().isEmpty ? null : value.toString();
  }

  @override
  String toString() {
    return 'ProjectMemberResponse{id: $id, projectRole: $projectRole, user: $user}';
  }
}

class UserInfoForTaskDto {
  final String? profileImage;
  final String? firstName;
  final String? secondName;
  final String? lastName;

  UserInfoForTaskDto({
    this.profileImage,
    this.firstName,
    this.secondName,
    this.lastName,
  });

  factory UserInfoForTaskDto.fromJson(Map<String, dynamic> json) {
    print('🔍 Parsing UserInfoForTaskDto: $json');
    
    return UserInfoForTaskDto(
      profileImage: _safeParseString(json['profile_image']),
      firstName: _safeParseString(json['first_name']),
      secondName: _safeParseString(json['second_name']),
      lastName: _safeParseString(json['last_name']),
    );
  }

  static String? _safeParseString(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return value.isEmpty ? null : value;
    }
    final stringValue = value.toString();
    return stringValue.isEmpty ? null : stringValue;
  }

  String get fullName {
    final parts = [
      firstName?.trim(),
      secondName?.trim(),
      lastName?.trim()
    ].where((part) => part != null && part.isNotEmpty).map((part) => part!).toList();
    
    return parts.isEmpty ? 'Не назначено' : parts.join(' ');
  }

  bool get hasAvatar => profileImage != null && profileImage!.isNotEmpty;

  @override
  String toString() {
    return 'UserInfoForTaskDto{firstName: $firstName, secondName: $secondName, lastName: $lastName, profileImage: ${profileImage != null ? "[SET]" : "null"}}';
  }
}