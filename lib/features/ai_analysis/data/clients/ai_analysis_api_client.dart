import '../../../bug_reports/domain/models/bug_screenshot.dart';
import '../models/ai_analysis_request.dart';
import '../models/ai_analysis_response.dart';

abstract class AiAnalysisApiClient {
  Future<AiAnalysisResponse> analyze(
    AiAnalysisRequest request, {
    BugScreenshot? screenshot,
  });
}
