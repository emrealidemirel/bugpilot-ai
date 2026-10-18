import 'dart:convert';
import 'dart:io';

import 'package:bugpilot_ai/services/ai_analysis_api_client.dart';
import 'package:bugpilot_ai/services/ai_analysis_exception.dart';
import 'package:bugpilot_ai/models/ai_analysis_request.dart';
import 'package:bugpilot_ai/models/ai_analysis_response.dart';
import 'package:bugpilot_ai/models/ai_api_error.dart';
import 'package:bugpilot_ai/services/remote_ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteAiBugAnalysisService', () {
    test(
      'maps bug to request, calls client once, and maps response to domain',
      () async {
        final client = _FakeAiAnalysisApiClient(
          response: AiAnalysisResponse.fromJson(_successFixture()),
        );
        final service = RemoteAiBugAnalysisService(apiClient: client);

        final analysis = await service.analyze(_bugReport());

        expect(client.callCount, 1);
        expect(client.lastRequest?.title, 'Login button stuck loading');
        expect(client.lastRequest?.environment.platform, 'android');
        expect(client.lastRequest?.logs, 'Stack trace');
        expect(analysis.severity, BugSeverity.high);
        expect(analysis.priority, BugPriority.p1);
        expect(analysis.testCases, hasLength(3));
      },
    );

    test('serializes preferences and omits screenshot when disabled', () async {
      final client = _FakeAiAnalysisApiClient(
        response: AiAnalysisResponse.fromJson(_successFixture()),
      );
      final service = RemoteAiBugAnalysisService(apiClient: client);
      final screenshotBug = _bugReport().copyWith(
        screenshot: const BugScreenshot(
          id: 'shot-001',
          localPath: '/tmp/local.png',
          fileName: 'local.png',
          mimeType: 'image/png',
          sizeBytes: 32,
        ),
      );

      await service.analyze(
        screenshotBug,
        preferences: const AiAnalysisPreferences(
          severity: false,
          priority: true,
          testCases: false,
          rootCause: false,
          screenshotAnalysis: false,
        ),
      );

      expect(client.lastRequest?.preferences.severity, isFalse);
      expect(client.lastRequest?.preferences.testCases, isFalse);
      expect(client.lastRequest?.preferences.rootCause, isFalse);
      expect(client.lastRequest?.preferences.screenshotAnalysis, isFalse);
      expect(client.lastScreenshot, isNull);
    });

    test('propagates typed analysis exceptions', () async {
      final client = _FakeAiAnalysisApiClient(
        error: const AiAnalysisException(
          code: AiAnalysisErrorCode.rateLimited,
          message: 'Too busy',
          requestId: 'req_429',
        ),
      );
      final service = RemoteAiBugAnalysisService(apiClient: client);

      expect(
        () => service.analyze(_bugReport()),
        throwsA(
          isA<AiAnalysisException>()
              .having(
                (error) => error.code,
                'code',
                AiAnalysisErrorCode.rateLimited,
              )
              .having((error) => error.requestId, 'requestId', 'req_429'),
        ),
      );
      expect(client.callCount, 1);
    });

    test('translates invalid response errors into typed exceptions', () async {
      final client = _FakeAiAnalysisApiClient(
        error: const FormatException('Bad JSON'),
      );
      final service = RemoteAiBugAnalysisService(apiClient: client);

      expect(
        () => service.analyze(_bugReport()),
        throwsA(
          isA<AiAnalysisException>().having(
            (error) => error.code,
            'code',
            AiAnalysisErrorCode.aiResponseInvalid,
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _successFixture() {
  return jsonDecode(
        File('test/fixtures/ai_analysis_success.json').readAsStringSync(),
      )
      as Map<String, dynamic>;
}

BugReport _bugReport() {
  return BugReport(
    id: 'bug-001',
    title: 'Login button stuck loading',
    description: 'The login screen remains loading after valid credentials.',
    expectedBehavior: 'The dashboard should open.',
    actualBehavior: 'The loading indicator remains visible.',
    platform: BugPlatform.android,
    device: 'Pixel 9',
    logs: 'Stack trace',
    status: BugStatus.open,
    createdAt: DateTime.utc(2026, 8, 19),
    updatedAt: DateTime.utc(2026, 8, 19),
  );
}

class _FakeAiAnalysisApiClient implements AiAnalysisApiClient {
  _FakeAiAnalysisApiClient({this.response, this.error});

  final AiAnalysisResponse? response;
  final Object? error;
  int callCount = 0;
  AiAnalysisRequest? lastRequest;
  BugScreenshot? lastScreenshot;

  @override
  Future<AiAnalysisResponse> analyze(
    AiAnalysisRequest request, {
    BugScreenshot? screenshot,
  }) async {
    callCount++;
    lastRequest = request;
    lastScreenshot = screenshot;

    final error = this.error;
    if (error != null) {
      throw error;
    }

    return response!;
  }
}
