import 'package:bugpilot_ai/models/bug_screenshot.dart';
import 'package:bugpilot_ai/models/ai_analysis_request.dart';
import 'package:bugpilot_ai/models/ai_analysis_response.dart';

abstract class AiAnalysisApiClient {
  Future<AiAnalysisResponse> analyze(
    AiAnalysisRequest request, {
    BugScreenshot? screenshot,
  });
}
