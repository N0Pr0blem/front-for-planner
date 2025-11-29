class InviteMemberRequest {
  final String username;
  final String projectRole;

  InviteMemberRequest({
    required this.username,
    required this.projectRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'project_role': projectRole,
    };
  }
}

class UpdateMemberRoleRequest {
  final String projectRole;

  UpdateMemberRoleRequest({
    required this.projectRole,
  });

  Map<String, dynamic> toJson() {
    return {
      'project_role': projectRole,
    };
  }
}