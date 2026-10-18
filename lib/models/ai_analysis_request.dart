import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';

class AiAnalysisRequest {
  const AiAnalysisRequest({
    required this.title,
    required this.description,
    required this.expectedBehavior,
    required this.actualBehavior,
    required this.environment,
    this.preferences = AiAnalysisPreferences.defaults,
    this.languageCode = 'en',
    this.logs,
  });

  factory AiAnalysisRequest.fromBugReport(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
    String languageCode = 'en',
  }) {
    return AiAnalysisRequest(
      title: bug.title,
      description: bug.description,
      expectedBehavior: bug.expectedBehavior,
      actualBehavior: bug.actualBehavior,
      environment: AiEnvironmentRequest(
        platform: bug.platform.jsonValue,
        device: bug.device,
        osVersion: bug.osVersion,
        appVersion: bug.appVersion,
      ),
      preferences: preferences,
      languageCode: languageCode,
      logs: bug.logs,
    );
  }

  final String title;
  final String description;
  final String expectedBehavior;
  final String actualBehavior;
  final AiEnvironmentRequest environment;
  final AiAnalysisPreferences preferences;
  final String languageCode;
  final String? logs;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'environment': environment.toJson(),
      'preferences': preferences.toJson(),
      'language': languageCode,
      if (_hasValue(logs)) 'logs': logs,
    };
  }
}

class AiEnvironmentRequest {
  const AiEnvironmentRequest({
    required this.platform,
    this.device,
    this.osVersion,
    this.appVersion,
  });

  final String platform;
  final String? device;
  final String? osVersion;
  final String? appVersion;

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      if (_hasValue(device)) 'device': device,
      if (_hasValue(osVersion)) 'osVersion': osVersion,
      if (_hasValue(appVersion)) 'appVersion': appVersion,
    };
  }
}

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty;
}
