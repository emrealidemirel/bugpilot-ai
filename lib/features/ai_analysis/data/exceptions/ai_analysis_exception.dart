import '../models/ai_api_error.dart';

class AiAnalysisException implements Exception {
  const AiAnalysisException({
    required this.code,
    required this.message,
    this.requestId,
  });

  factory AiAnalysisException.fromApiError(AiApiError error) {
    return AiAnalysisException(
      code: error.code,
      message: error.message,
      requestId: error.requestId,
    );
  }

  final AiAnalysisErrorCode code;
  final String message;
  final String? requestId;

  String get userMessage => code.userMessage;

  @override
  String toString() {
    return 'AiAnalysisException(${code.jsonValue}, requestId: $requestId)';
  }
}
