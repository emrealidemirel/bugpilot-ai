import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/services/openai_responses_client.dart';
import 'package:bugpilot_ai/services/ai_analysis_exception.dart';
import 'package:bugpilot_ai/models/ai_api_error.dart';
import 'package:bugpilot_ai/models/ai_analysis_request.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAiResponsesClient analysis', () {
    test('sends a structured request and parses the response', () async {
      late http.Request capturedRequest;
      final client = OpenAiResponsesClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(_response(_analysis()), 200);
        }),
      );

      final response = await client.analyze(_request());
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      final input = body['input'] as List<dynamic>;
      final userMessage = input.single as Map<String, dynamic>;
      final content = userMessage['content'] as List<dynamic>;

      expect(capturedRequest.url, Uri.https('api.openai.com', '/v1/responses'));
      expect(capturedRequest.headers['authorization'], 'Bearer test-key');
      expect(body['store'], isFalse);
      expect(body['text'], containsPair('format', isA<Map<String, dynamic>>()));
      expect(
        (content.single as Map<String, dynamic>)['text'],
        contains(_request().title),
      );
      expect(response.toDomain().priority, BugPriority.p1);
    });

    test('includes an enabled screenshot as base64 input', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'bugpilot-ai-test-',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final screenshot = await File(
        '${tempDir.path}/screen.png',
      ).writeAsBytes([1, 2, 3]);
      late Map<String, dynamic> body;
      final client = OpenAiResponsesClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(_response(_analysis()), 200);
        }),
      );

      await client.analyze(
        _request(),
        screenshot: BugScreenshot(
          id: 'screenshot-1',
          localPath: screenshot.path,
          fileName: 'screen.png',
          mimeType: 'image/png',
          sizeBytes: 3,
        ),
      );

      final message = (body['input'] as List).single as Map<String, dynamic>;
      final content = message['content'] as List;
      expect(content, hasLength(2));
      expect(content.last, containsPair('type', 'input_image'));
      expect(
        content.last,
        containsPair('image_url', 'data:image/png;base64,AQID'),
      );
    });

    test('maps provider errors to stable error codes', () async {
      await _expectProviderError(
        statusCode: 401,
        providerError: {'code': 'invalid_api_key'},
        expectedCode: AiAnalysisErrorCode.invalidApiKey,
      );
      await _expectProviderError(
        statusCode: 429,
        providerError: {'code': 'insufficient_quota'},
        expectedCode: AiAnalysisErrorCode.quotaExceeded,
      );
      await _expectProviderError(
        statusCode: 429,
        providerError: {'code': 'rate_limit_exceeded'},
        expectedCode: AiAnalysisErrorCode.rateLimited,
      );
      await _expectProviderError(
        statusCode: 503,
        providerError: {'code': 'server_error'},
        expectedCode: AiAnalysisErrorCode.serviceUnavailable,
      );
    });

    test('maps invalid structured output', () async {
      final invalid = _analysis()..['rootCauseConfidence'] = 2;
      final client = OpenAiResponsesClient(
        apiKey: 'test-key',
        httpClient: MockClient(
          (request) async => http.Response(_response(invalid), 200),
        ),
      );

      await expectLater(
        client.analyze(_request()),
        throwsA(
          isA<AiAnalysisException>().having(
            (error) => error.code,
            'code',
            AiAnalysisErrorCode.aiResponseInvalid,
          ),
        ),
      );
    });

    test('maps network failures', () async {
      final client = OpenAiResponsesClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          throw const SocketException('No route to host');
        }),
      );

      await expectLater(
        client.analyze(_request()),
        throwsA(
          isA<AiAnalysisException>().having(
            (error) => error.code,
            'code',
            AiAnalysisErrorCode.networkError,
          ),
        ),
      );
    });
  });
}

Future<void> _expectProviderError({
  required int statusCode,
  required Map<String, dynamic> providerError,
  required AiAnalysisErrorCode expectedCode,
}) async {
  final client = OpenAiResponsesClient(
    apiKey: 'test-key',
    httpClient: MockClient(
      (request) async =>
          http.Response(jsonEncode({'error': providerError}), statusCode),
    ),
  );

  await expectLater(
    client.analyze(_request()),
    throwsA(
      isA<AiAnalysisException>().having(
        (error) => error.code,
        'code',
        expectedCode,
      ),
    ),
  );
}

AiAnalysisRequest _request() => const AiAnalysisRequest(
  title: 'Login button stuck loading',
  description: 'The login screen remains loading after valid credentials.',
  expectedBehavior: 'The dashboard should open.',
  actualBehavior: 'The loading indicator remains visible.',
  environment: AiEnvironmentRequest(platform: 'android'),
  logs: 'Stack trace',
);

Map<String, dynamic> _analysis() => {
  'severity': 'high',
  'severityReason': 'Blocks a core workflow.',
  'priority': 'p1',
  'priorityReason': 'Needs attention soon.',
  'reproductionSteps': ['Open the app', 'Submit valid credentials'],
  'testCases': [
    {
      'id': 'TC-01',
      'type': 'positive',
      'title': 'Valid login succeeds',
      'given': 'A user is on the login screen',
      'when': 'Valid credentials are submitted',
      'then': 'The dashboard opens',
    },
  ],
  'possibleRootCause': 'Loading state may not reset.',
  'rootCauseConfidence': 0.72,
  'missingInformation': [],
  'qualityScore': 82,
};

String _response(Map<String, dynamic> payload) => jsonEncode({
  'output': [
    {
      'type': 'message',
      'content': [
        {'type': 'output_text', 'text': jsonEncode(payload)},
      ],
    },
  ],
});
