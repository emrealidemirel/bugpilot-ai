import '../../../bug_reports/domain/models/bug_report.dart';
import '../models/ai_analysis_preferences.dart';
import '../models/ai_bug_analysis.dart';

abstract class AiBugAnalysisService {
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
  });
}
