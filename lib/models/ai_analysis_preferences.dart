import 'package:bugpilot_ai/models/app_settings.dart';

class AiAnalysisPreferences {
  const AiAnalysisPreferences({
    this.severity = true,
    this.priority = true,
    this.testCases = true,
    this.rootCause = true,
    this.screenshotAnalysis = true,
  });

  factory AiAnalysisPreferences.fromSettings(AppSettings settings) {
    return AiAnalysisPreferences(
      severity: settings.aiSeverityEnabled,
      priority: settings.aiPriorityEnabled,
      testCases: settings.aiTestCasesEnabled,
      rootCause: settings.aiRootCauseEnabled,
      screenshotAnalysis: settings.screenshotAnalysisEnabled,
    );
  }

  static const defaults = AiAnalysisPreferences();

  final bool severity;
  final bool priority;
  final bool testCases;
  final bool rootCause;
  final bool screenshotAnalysis;

  Map<String, dynamic> toJson() {
    return {
      'severity': severity,
      'priority': priority,
      'testCases': testCases,
      'rootCause': rootCause,
      'screenshotAnalysis': screenshotAnalysis,
    };
  }
}
