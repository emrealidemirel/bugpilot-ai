import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/services/openai_responses_client.dart';
import 'package:bugpilot_ai/services/ai_analysis_exception.dart';
import 'package:bugpilot_ai/models/ai_api_error.dart';
import 'package:bugpilot_ai/models/duplicate_check_request.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('OpenAiResponsesClient duplicate checks', () {
    test('sends candidates and parses structured matches', () async {
      late http.Request capturedRequest;
      final client = OpenAiResponsesClient(
        apiKey: 'test-key',
        httpClient: MockClient((request) async {
          capturedRequest = request;
          return http.Response(_response(_matches()), 200);
        }),
      );

      final response = await client.checkDuplicates(_request());
      final body = jsonDecode(capturedRequest.body) as Map<String, dynamic>;
      final input = jsonDecode(body['input'] as String) as Map<String, dynamic>;

      expect(capturedRequest.url, Uri.https('api.openai.com', '/v1/responses'));
      expect(
        input['newBug'],
        containsPair('title', 'Login button stuck loading'),
      );
      expect(
        input['existingCandidates'],
        contains(containsPair('title', 'Existing login spinner never clears')),
      );
      expect(
        response.matches.single.similarity,
        DuplicateSimilarity.likelyDuplicate,
      );
    });

    test('maps provider rate limits', () async {
      final client = OpenAiResponsesClient(
        apiKey: 'test-key',
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'error': {'code': 'rate_limit_exceeded'},
            }),
            429,
          ),
        ),
      );

      await expectLater(
        client.checkDuplicates(_request()),
        throwsA(
          isA<AiAnalysisException>().having(
            (error) => error.code,
            'code',
            AiAnalysisErrorCode.rateLimited,
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

DuplicateCheckRequest _request() => DuplicateCheckRequest(
  bug: const DuplicateDraftBugRequest(
    title: 'Login button stuck loading',
    description: 'Login remains loading.',
    expectedBehavior: 'Dashboard opens.',
    actualBehavior: 'Spinner remains visible.',
    platform: 'android',
  ),
  candidates: const [
    DuplicateCandidateRequest(
      id: 'bug-001',
      title: 'Existing login spinner never clears',
      description: 'Login never completes.',
      expectedBehavior: 'Dashboard opens.',
      actualBehavior: 'Spinner never clears.',
      platform: 'android',
      severity: 'high',
      status: 'open',
    ),
  ],
);

Map<String, dynamic> _matches() => {
  'matches': [
    {
      'bugId': 'bug-001',
      'similarity': 'likelyDuplicate',
      'confidence': 0.83,
      'reason': 'Both reports describe login remaining stuck.',
    },
  ],
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
