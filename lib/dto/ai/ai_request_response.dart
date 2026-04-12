// dto/ai/ai_request_response.dart
class AIRequestResponse {
  final int requestId;
  final String response;
  final String pattern;
  final String originalRequest;
  final int processingTimeMs;

  AIRequestResponse({
    required this.requestId,
    required this.response,
    required this.pattern,
    required this.originalRequest,
    required this.processingTimeMs,
  });

  factory AIRequestResponse.fromJson(Map<String, dynamic> json) {
    return AIRequestResponse(
      requestId: json['requestId'] as int,
      response: json['response'] as String,
      pattern: json['pattern'] as String,
      originalRequest: json['originalRequest'] as String,
      processingTimeMs: json['processingTimeMs'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'response': response,
      'pattern': pattern,
      'originalRequest': originalRequest,
      'processingTimeMs': processingTimeMs,
    };
  }
}