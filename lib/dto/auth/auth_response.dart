class AuthResponse {
  final String? token;
  final DateTime? issuedAt;
  final DateTime? expiresAt;

  AuthResponse({
    this.token,
    this.issuedAt,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      issuedAt: _parseDateTime(json['issued_at']),
      expiresAt: _parseDateTime(json['expires_at']),
    );
  }

  static DateTime? _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return null;
    
    try {
      if (dateValue is int) {
        // Если приходит timestamp в миллисекундах
        return DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is String) {
        // Если приходит ISO строка
        return DateTime.parse(dateValue);
      } else {
        print('Неизвестный формат даты: $dateValue (тип: ${dateValue.runtimeType})');
        return null;
      }
    } catch (e) {
      print('Ошибка парсинга даты: $dateValue. Ошибка: $e');
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'issued_at': issuedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
}