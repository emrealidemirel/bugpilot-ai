import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/features/ai_analysis/data/exceptions/ai_analysis_exception.dart';
import 'package:bugpilot_ai/features/ai_analysis/data/models/ai_api_error.dart';
import 'package:bugpilot_ai/features/duplicate_detection/data/clients/http_duplicate_detection_api_client.dart';
import 'package:bugpilot_ai/features/duplicate_detection/data/models/duplicate_check_request.dart';
import 'package:bugpilot_ai/features/duplicate_detection/domain/models/duplicate_check_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('HttpDuplicateDetectionApiClient', () {
    test('posts request JSON and parses successful response', () async {
      late Uri capturedUrl;
      late Map<String, dynamic> capturedBody;
      final client = HttpDuplicateDetectionApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          capturedUrl = request.url;
          capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode(_successResponse()), 200);
        }),
      );

      final response = await client.checkDuplicates(_request());

      expect(
        capturedUrl.toString(),
        'http://localhost:3000/api/v1/ai/check-duplicates',
      );
      expect((capturedBody['candidates'] as List), hasLength(1));
      expect(
        response.matches.single.similarity,
        DuplicateSimilarity.likelyDuplicate,
      );
    });

    test('maps backend errors', () async {
      final client = HttpDuplicateDetectionApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'error': {
                'code': 'RATE_LIMITED',
                'message': 'Backend message',
                'requestId': 'req_test',
              },
            }),
            429,
          ),
        ),
      );

      await expectLater(
        client.checkDuplicates(_request()),
        throwsA(
          isA<AiAnalysisException>()
              .having(
                (error) => error.code,
                'code',
                AiAnalysisErrorCode.rateLimited,
              )
              .having((error) => error.requestId, 'requestId', 'req_test'),
        ),
      );
    });

    test('maps network failure', () async {
      final client = HttpDuplicateDetectionApiClient(
        baseUrl: Uri.parse('http://localhost:3000'),
        httpClient: MockClient((request) async {
          throw const SocketException('No route to host');
        }),
      );

      await expectLater(
        client.checkDuplicates(_request()),
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

DuplicateCheckRequest _request() {
  return DuplicateCheckRequest(
    bug: const DuplicateDraftBugRequest(
      title: 'Login button stuck loading',
      description: 'Login remains loading.',
      expectedBehavior: 'Dashboard opens.',
      actualBehavior: 'Spinner remains visible.',
      platform: 'android',
    ),
    candidates: [
      const DuplicateCandidateRequest(
        id: 'bug-001',
        title: 'Login remains loading',
        description: 'Login never completes.',
        expectedBehavior: 'Dashboard opens.',
        actualBehavior: 'Spinner never clears.',
        platform: 'android',
        severity: 'high',
        status: 'open',
      ),
    ],
  );
}

Map<String, dynamic> _successResponse() {
  return {
    'matches': [
      {
        'bugId': 'bug-001',
        'similarity': 'likelyDuplicate',
        'confidence': 0.83,
        'reason': 'Both reports describe login remaining stuck.',
      },
    ],
  };
}
