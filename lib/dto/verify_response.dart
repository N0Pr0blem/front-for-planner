class VerifyResponse {
  final String message;
  final bool verified;
  final String? errorCode;

  VerifyResponse({
    required this.message,
    required this.verified,
    this.errorCode,
  });

  factory VerifyResponse.fromJson(Map<String, dynamic> json) {
    // Если есть error_code - это ошибка
    if (json['error_code'] != null) {
      return VerifyResponse(
        message: json['message'] ?? 'Verification failed',
        verified: false,
        errorCode: json['error_code'],
      );
    } else {
      // Успешный ответ (MessageResponseDto)
      return VerifyResponse(
        message: json['message'] ?? 'Verification completed',
        verified: true,
        errorCode: null,
      );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'verified': verified,
      if (errorCode != null) 'error_code': errorCode,
    };
  }

  bool get isSuccess => verified && errorCode == null;
  bool get isError => errorCode != null;
}