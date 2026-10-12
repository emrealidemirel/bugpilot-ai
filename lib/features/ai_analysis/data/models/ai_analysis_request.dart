import '../../../bug_reports/domain/enums/bug_platform.dart';
import '../../../bug_reports/domain/models/bug_report.dart';
import '../../domain/models/ai_analysis_preferences.dart';

class AiAnalysisRequest {
  const AiAnalysisRequest({
    required this.title,
    required this.description,
    required this.expectedBehavior,
    required this.actualBehavior,
    required this.environment,
    this.preferences = AiAnalysisPreferences.defaults,
    this.logs,
  });

  factory AiAnalysisRequest.fromBugReport(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
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
      logs: bug.logs,
    );
  }

  final String title;
  final String description;
  final String expectedBehavior;
  final String actualBehavior;
  final AiEnvironmentRequest environment;
  final AiAnalysisPreferences preferences;
  final String? logs;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'environment': environment.toJson(),
      'preferences': preferences.toJson(),
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
