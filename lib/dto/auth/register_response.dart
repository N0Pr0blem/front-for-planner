class RegisterResponse {
  final String username;
  final String? firstName;
  final bool enabled;
  final String role;

  RegisterResponse({
    required this.username,
    this.firstName,
    required this.enabled,
    required this.role,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      username: json['username'],
      firstName: json['first_name'],
      enabled: json['enabled'],
      role: json['role'],
    );
  }
}