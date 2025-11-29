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
    return ProjectMemberResponse(
      id: json['id'],
      projectRole: json['projectRole'],
      user: UserInfoForTaskDto.fromJson(json['user']),
    );
  }
}

class UserInfoForTaskDto {
  final String? profileImage;
  final String? firstName;
  final String? secondName;

  UserInfoForTaskDto({
    this.profileImage,
    this.firstName,
    this.secondName,
  });

  factory UserInfoForTaskDto.fromJson(Map<String, dynamic> json) {
    return UserInfoForTaskDto(
      profileImage: json['profileImage'],
      firstName: json['firstName'],
      secondName: json['secondName'],
    );
  }

  String get fullName {
    final parts = [firstName, secondName].where((part) => part != null).cast<String>();
    return parts.isEmpty ? 'Не назначено' : parts.join(' ');
  }

  bool get hasAvatar => profileImage != null && profileImage!.isNotEmpty;
}