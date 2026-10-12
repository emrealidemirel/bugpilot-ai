import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/features/ai_analysis/data/clients/http_ai_analysis_api_client.dart';
import 'package:bugpilot_ai/features/ai_analysis/data/exceptions/ai_analysis_exception.dart';
import 'package:bugpilot_ai/features/ai_analysis/data/models/ai_analysis_request.dart';
import 'package:bugpilot_ai/features/ai_analysis/data/models/ai_api_error.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/models/bug_screenshot.dart';
import 'package:bugpilot_ai/features/bug_reports/domain/enums/bug_priority.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpAiAnalysisApiClient', () {
    test('posts request JSON and parses successful response', () async {
      late Uri capturedUrl;
      late Map<String, dynamic> capturedBody;
      final client = HttpAiAnalysisApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          capturedUrl = request.url;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(_successResponse()), 200);
        }),
      );

      final response = await client.analyze(_request());

      expect(
        capturedUrl.toString(),
        'http://localhost:3000/api/v1/ai/analyze-bug',
      );
      expect(capturedBody['title'], 'Login button stuck loading');
      expect(
        (capturedBody['preferences'] as Map<String, dynamic>)['severity'],
        isTrue,
      );
      expect(
        (capturedBody['environment'] as Map<String, dynamic>)['platform'],
        'android',
      );
      expect(response.toDomain().priority, BugPriority.p1);
    });

    test('posts multipart request when screenshot is present', () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'bugpilot_api_client_test_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final screenshotFile = await File(
        '${tempDir.path}/login.png',
      ).writeAsBytes(List<int>.filled(32, 1));
      late Uri capturedUrl;
      late String capturedContentType;
      late String capturedBody;
      final client = HttpAiAnalysisApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          capturedUrl = request.url;
          capturedContentType = request.headers['content-type']!;
          capturedBody = utf8.decode(request.bodyBytes);
          return http.Response(jsonEncode(_successResponse()), 200);
        }),
      );

      final response = await client.analyze(
        _request(),
        screenshot: BugScreenshot(
          id: 'shot-001',
          localPath: screenshotFile.path,
          fileName: 'login.png',
          mimeType: 'image/png',
          sizeBytes: 32,
        ),
      );

      expect(
        capturedUrl.toString(),
        'http://localhost:3000/api/v1/ai/analyze-bug',
      );
      expect(capturedContentType, contains('multipart/form-data'));
      expect(capturedBody, contains('name="bug"'));
      expect(capturedBody, contains('"title":"Login button stuck loading"'));
      expect(capturedBody, contains('name="screenshot"'));
      expect(capturedBody, contains('filename="login.png"'));
      expect(capturedBody, contains('content-type: image/png'));
      expect(response.toDomain().priority, BugPriority.p1);
    });

    test('maps standard backend errors', () async {
      await _expectError(
        400,
        'INVALID_REQUEST',
        AiAnalysisErrorCode.invalidRequest,
      );
      await _expectError(429, 'RATE_LIMITED', AiAnalysisErrorCode.rateLimited);
      await _expectError(
        503,
        'SERVICE_UNAVAILABLE',
        AiAnalysisErrorCode.serviceUnavailable,
      );
    });

    test('maps timeout', () async {
      final client = HttpAiAnalysisApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        timeout: const Duration(milliseconds: 1),
        httpClient: MockClient((request) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response(jsonEncode(_successResponse()), 200);
        }),
      );

      await expectLater(
        client.analyze(_request()),
        throwsA(
          isA<AiAnalysisException>().having(
            (error) => error.code,
            'code',
            AiAnalysisErrorCode.requestTimeout,
          ),
        ),
      );
    });

    test('maps malformed JSON', () async {
      final client = HttpAiAnalysisApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient(
          (request) async => http.Response('not json', 200),
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

    test('maps malformed analysis payload', () async {
      final body = _successResponse();
      (body['analysis'] as Map<String, dynamic>)['rootCauseConfidence'] = 2;
      final client = HttpAiAnalysisApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient(
          (request) async => http.Response(jsonEncode(body), 200),
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

    test('maps network failure', () async {
      final client = HttpAiAnalysisApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
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

Future<void> _expectError(
  int statusCode,
  String backendCode,
  AiAnalysisErrorCode expectedCode,
) async {
  final client = HttpAiAnalysisApiClient(
    baseUrl: Uri.parse('http://localhost:3000'),
    httpClient: MockClient(
      (request) async => http.Response(
        jsonEncode({
          'error': {
            'code': backendCode,
            'message': 'Backend message',
            'requestId': 'req_test',
          },
        }),
        statusCode,
      ),
    ),
  );

  await expectLater(
    client.analyze(_request()),
    throwsA(
      isA<AiAnalysisException>()
          .having((error) => error.code, 'code', expectedCode)
          .having((error) => error.requestId, 'requestId', 'req_test'),
    ),
  );
}

AiAnalysisRequest _request() {
  return const AiAnalysisRequest(
    title: 'Login button stuck loading',
    description: 'The login screen remains loading after valid credentials.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The loading indicator remains visible.',
    environment: AiEnvironmentRequest(platform: 'android'),
    logs: 'Stack trace',
  );
}

Map<String, dynamic> _successResponse() {
  return {
    'analysis': {
      'severity': 'high',
      'severityReason': 'The issue blocks a core workflow.',
      'priority': 'p1',
      'priorityReason': 'The issue should be addressed quickly.',
      'reproductionSteps': ['Open the app', 'Submit valid credentials'],
      'testCases': [
        {
          'id': 'TC-01',
          'type': 'positive',
          'title': 'Valid login completes successfully',
          'given': 'A registered user is on the login screen',
          'when': 'Valid credentials are submitted',
          'then': 'The user should reach the dashboard',
        },
      ],
      'possibleRootCause':
          'A possible cause is that loading state is not reset.',
      'rootCauseConfidence': 0.72,
      'missingInformation': ['Network conditions were not provided.'],
      'qualityScore': 82,
    },
  };
}
