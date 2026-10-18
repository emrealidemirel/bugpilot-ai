import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';
import 'package:bugpilot_ai/services/ai_analysis_api_client.dart';
import 'package:bugpilot_ai/services/ai_analysis_exception.dart';
import 'package:bugpilot_ai/models/ai_analysis_request.dart';
import 'package:bugpilot_ai/models/ai_api_error.dart';

class RemoteAiBugAnalysisService implements AiBugAnalysisService {
  const RemoteAiBugAnalysisService({required this.apiClient});

  final AiAnalysisApiClient apiClient;

  @override
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
    String languageCode = 'en',
  }) async {
    try {
      final request = AiAnalysisRequest.fromBugReport(
        bug,
        preferences: preferences,
        languageCode: languageCode,
      );
      final response = await apiClient.analyze(
        request,
        screenshot: preferences.screenshotAnalysis ? bug.screenshot : null,
      );
      return response.toDomain();
    } on AiAnalysisException {
      rethrow;
    } on FormatException catch (error) {
      throw AiAnalysisException(
        code: AiAnalysisErrorCode.aiResponseInvalid,
        message: error.message,
      );
    } on ArgumentError catch (error) {
      throw AiAnalysisException(
        code: AiAnalysisErrorCode.aiResponseInvalid,
        message: error.message,
      );
    } on TypeError catch (error) {
      throw AiAnalysisException(
        code: AiAnalysisErrorCode.aiResponseInvalid,
        message: error.toString(),
      );
    } on Object {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.unknownError,
        message: 'Something went wrong while analyzing this bug report.',
      );
    }
  }
}
