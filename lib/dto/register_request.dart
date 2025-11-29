class RegisterRequest {
  final String username;
  final String password;
  final String firstName;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.firstName,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'first_name': firstName,
    };
  }
}