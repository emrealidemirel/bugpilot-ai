import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/features/ai_analysis/data/exceptions/ai_analysis_exception.dart';
import 'package:bugpilot_ai/features/ai_analysis/data/models/ai_api_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiApiError', () {
    test('parses error fixture', () {
      final error = AiApiError.fromJson(_errorFixture());

      expect(error.code, AiAnalysisErrorCode.rateLimited);
      expect(
        error.message,
        'The analysis service is receiving too many requests.',
      );
      expect(error.requestId, 'req_429');
      expect(
        error.userMessage,
        'AI analysis is temporarily busy. Please try again shortly.',
      );
    });

    test('maps stable error codes to friendly messages', () {
      expect(
        _messageFor('INVALID_REQUEST'),
        'Some bug report information is invalid.',
      );
      expect(
        _messageFor('SERVICE_UNAVAILABLE'),
        'AI analysis is temporarily unavailable.',
      );
      expect(
        _messageFor('REQUEST_TIMEOUT'),
        'The analysis took too long. Please try again.',
      );
      expect(
        _messageFor('NETWORK_ERROR'),
        'Could not connect to AI analysis. Check your connection and backend URL.',
      );
      expect(
        _messageFor('UNKNOWN_FUTURE_CODE'),
        'Something went wrong while analyzing this bug report.',
      );
    });

    test('creates typed analysis exception from API error', () {
      final exception = AiAnalysisException.fromApiError(
        const AiApiError(
          code: AiAnalysisErrorCode.invalidRequest,
          message: 'Invalid payload',
          requestId: 'req_invalid',
        ),
      );

      expect(exception.code, AiAnalysisErrorCode.invalidRequest);
      expect(exception.requestId, 'req_invalid');
      expect(exception.userMessage, 'Some bug report information is invalid.');
    });
  });
}

String _messageFor(String code) {
  return AiApiError.fromJson({
    'error': {'code': code, 'message': 'Backend detail'},
  }).userMessage;
}

Map<String, dynamic> _errorFixture() {
  return jsonDecode(
        File('test/fixtures/ai_analysis_error.json').readAsStringSync(),
      )
      as Map<String, dynamic>;
}
