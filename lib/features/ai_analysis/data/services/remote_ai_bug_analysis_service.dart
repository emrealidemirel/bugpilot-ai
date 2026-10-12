import '../../../bug_reports/domain/models/bug_report.dart';
import '../../domain/models/ai_analysis_preferences.dart';
import '../../domain/models/ai_bug_analysis.dart';
import '../../domain/services/ai_bug_analysis_service.dart';
import '../clients/ai_analysis_api_client.dart';
import '../exceptions/ai_analysis_exception.dart';
import '../models/ai_analysis_request.dart';
import '../models/ai_api_error.dart';

class RemoteAiBugAnalysisService implements AiBugAnalysisService {
  const RemoteAiBugAnalysisService({required this.apiClient});

  final AiAnalysisApiClient apiClient;

  @override
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
  }) async {
    try {
      final request = AiAnalysisRequest.fromBugReport(
        bug,
        preferences: preferences,
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
