class VerifyRequest {
  final String username;
  final String code;

  VerifyRequest({
    required this.username,
    required this.code,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'code': code,
    };
  }
}