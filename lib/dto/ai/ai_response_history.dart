// lib/dto/ai/ai_response_history.dart
class AIResponseHistory {
  final int responseId;
  final String request;
  final String response;
  final String pattern;
  final int processingTimeMs;
  final DateTime sendDate;

  AIResponseHistory({
    required this.responseId,
    required this.request,
    required this.response,
    required this.pattern,
    required this.processingTimeMs,
    required this.sendDate,
  });

  factory AIResponseHistory.fromJson(Map<String, dynamic> json) {
    return AIResponseHistory(
      responseId: json['responseId'] as int,
      request: json['request'] as String,
      response: json['response'] as String,
      pattern: json['pattern'] as String,
      processingTimeMs: json['processingTimeMs'] as int,
      sendDate: DateTime.parse(json['sendDate'] as String),
    );
  }

  String get formattedDate {
    return '${sendDate.day.toString().padLeft(2, '0')}.${sendDate.month.toString().padLeft(2, '0')}.${sendDate.year} ${sendDate.hour.toString().padLeft(2, '0')}:${sendDate.minute.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    return '${sendDate.hour.toString().padLeft(2, '0')}:${sendDate.minute.toString().padLeft(2, '0')}';
  }
}