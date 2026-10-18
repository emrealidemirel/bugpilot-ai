enum AiAnalysisErrorCode {
  invalidRequest,
  aiAnalysisFailed,
  invalidApiKey,
  aiResponseInvalid,
  rateLimited,
  quotaExceeded,
  serviceUnavailable,
  requestTimeout,
  networkError,
  screenshotUploadFailed,
  unknownError,
}

extension AiAnalysisErrorCodePresentation on AiAnalysisErrorCode {
  String get jsonValue {
    return switch (this) {
      AiAnalysisErrorCode.invalidRequest => 'INVALID_REQUEST',
      AiAnalysisErrorCode.aiAnalysisFailed => 'AI_ANALYSIS_FAILED',
      AiAnalysisErrorCode.invalidApiKey => 'INVALID_API_KEY',
      AiAnalysisErrorCode.aiResponseInvalid => 'AI_RESPONSE_INVALID',
      AiAnalysisErrorCode.rateLimited => 'RATE_LIMITED',
      AiAnalysisErrorCode.quotaExceeded => 'AI_QUOTA_EXCEEDED',
      AiAnalysisErrorCode.serviceUnavailable => 'SERVICE_UNAVAILABLE',
      AiAnalysisErrorCode.requestTimeout => 'REQUEST_TIMEOUT',
      AiAnalysisErrorCode.networkError => 'NETWORK_ERROR',
      AiAnalysisErrorCode.screenshotUploadFailed => 'SCREENSHOT_UPLOAD_FAILED',
      AiAnalysisErrorCode.unknownError => 'UNKNOWN_ERROR',
    };
  }

  String get userMessage {
    return switch (this) {
      AiAnalysisErrorCode.invalidRequest =>
        'Some bug report information is invalid.',
      AiAnalysisErrorCode.rateLimited =>
        'AI analysis is temporarily busy. Please try again shortly.',
      AiAnalysisErrorCode.quotaExceeded =>
        'The AI provider has no available quota. Check the API key project billing and limits.',
      AiAnalysisErrorCode.serviceUnavailable =>
        'AI analysis is temporarily unavailable.',
      AiAnalysisErrorCode.invalidApiKey =>
        'The OpenAI API key is invalid or does not have access to this model.',
      AiAnalysisErrorCode.requestTimeout =>
        'The analysis took too long. Please try again.',
      AiAnalysisErrorCode.networkError =>
        'Could not connect to OpenAI. Check your internet connection.',
      AiAnalysisErrorCode.screenshotUploadFailed =>
        'The screenshot could not be uploaded for analysis.',
      AiAnalysisErrorCode.aiResponseInvalid =>
        'The AI returned an invalid analysis. Please try again.',
      AiAnalysisErrorCode.aiAnalysisFailed ||
      AiAnalysisErrorCode.unknownError =>
        'Something went wrong while analyzing this bug report.',
    };
  }
}

AiAnalysisErrorCode aiAnalysisErrorCodeFromJson(String value) {
  return switch (value) {
    'INVALID_REQUEST' => AiAnalysisErrorCode.invalidRequest,
    'AI_ANALYSIS_FAILED' => AiAnalysisErrorCode.aiAnalysisFailed,
    'INVALID_API_KEY' => AiAnalysisErrorCode.invalidApiKey,
    'AI_RESPONSE_INVALID' => AiAnalysisErrorCode.aiResponseInvalid,
    'RATE_LIMITED' => AiAnalysisErrorCode.rateLimited,
    'AI_QUOTA_EXCEEDED' => AiAnalysisErrorCode.quotaExceeded,
    'SERVICE_UNAVAILABLE' => AiAnalysisErrorCode.serviceUnavailable,
    'REQUEST_TIMEOUT' => AiAnalysisErrorCode.requestTimeout,
    'NETWORK_ERROR' => AiAnalysisErrorCode.networkError,
    'SCREENSHOT_UPLOAD_FAILED' => AiAnalysisErrorCode.screenshotUploadFailed,
    'UNKNOWN_ERROR' => AiAnalysisErrorCode.unknownError,
    _ => AiAnalysisErrorCode.unknownError,
  };
}

class AiApiError {
  const AiApiError({
    required this.code,
    required this.message,
    this.requestId,
    this.rawCode,
  });

  factory AiApiError.fromJson(Map<String, dynamic> json) {
    final error = json['error'];
    final payload = error is Map<String, dynamic> ? error : json;
    final rawCode = payload['code'] as String? ?? 'UNKNOWN_ERROR';

    return AiApiError(
      code: aiAnalysisErrorCodeFromJson(rawCode),
      rawCode: rawCode,
      message:
          payload['message'] as String? ??
          'The bug report could not be analyzed.',
      requestId: payload['requestId'] as String?,
    );
  }

  final AiAnalysisErrorCode code;
  final String message;
  final String? requestId;
  final String? rawCode;

  String get userMessage => code.userMessage;

  Map<String, dynamic> toJson() {
    return {
      'error': {
        'code': rawCode ?? code.jsonValue,
        'message': message,
        if (requestId != null) 'requestId': requestId,
      },
    };
  }
}
