import 'package:bugpilot_ai/models/bug_platform.dart';
import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_status.dart';
import 'bug_screenshot.dart';
import 'bug_test_case.dart';

const _unset = Object();

class BugReport {
  BugReport({
    required this.id,
    required this.title,
    required this.description,
    required this.expectedBehavior,
    required this.actualBehavior,
    required this.platform,
    this.device,
    this.osVersion,
    this.appVersion,
    this.logs,
    this.severity,
    this.priority,
    required this.status,
    List<String> reproductionSteps = const [],
    List<BugTestCase> testCases = const [],
    this.possibleRootCause,
    this.rootCauseConfidence,
    this.screenshot,
    required this.createdAt,
    required this.updatedAt,
  }) : assert(
         rootCauseConfidence == null ||
             (rootCauseConfidence >= 0 && rootCauseConfidence <= 1),
         'rootCauseConfidence must be between 0.0 and 1.0.',
       ),
       reproductionSteps = List.unmodifiable(reproductionSteps),
       testCases = List.unmodifiable(testCases);

  factory BugReport.fromJson(Map<String, dynamic> json) {
    final severity = json['severity'];
    final priority = json['priority'];

    return BugReport(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      expectedBehavior: json['expectedBehavior'] as String,
      actualBehavior: json['actualBehavior'] as String,
      platform: bugPlatformFromJson(json['platform'] as String),
      device: json['device'] as String?,
      osVersion: json['osVersion'] as String?,
      appVersion: json['appVersion'] as String?,
      logs: json['logs'] as String?,
      severity: severity == null
          ? null
          : bugSeverityFromJson(severity as String),
      priority: priority == null
          ? null
          : bugPriorityFromJson(priority as String),
      status: bugStatusFromJson(json['status'] as String),
      reproductionSteps:
          (json['reproductionSteps'] as List<dynamic>? ?? const [])
              .map((step) => step as String)
              .toList(),
      testCases: (json['testCases'] as List<dynamic>? ?? const [])
          .map(
            (testCase) =>
                BugTestCase.fromJson(testCase as Map<String, dynamic>),
          )
          .toList(),
      possibleRootCause: json['possibleRootCause'] as String?,
      rootCauseConfidence: (json['rootCauseConfidence'] as num?)?.toDouble(),
      screenshot: json['screenshot'] == null
          ? null
          : BugScreenshot.fromJson(json['screenshot'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String title;
  final String description;
  final String expectedBehavior;
  final String actualBehavior;
  final BugPlatform platform;
  final String? device;
  final String? osVersion;
  final String? appVersion;
  final String? logs;
  final BugSeverity? severity;
  final BugPriority? priority;
  final BugStatus status;
  final List<String> reproductionSteps;
  final List<BugTestCase> testCases;
  final String? possibleRootCause;
  final double? rootCauseConfidence;
  final BugScreenshot? screenshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  BugReport copyWith({
    String? id,
    String? title,
    String? description,
    String? expectedBehavior,
    String? actualBehavior,
    BugPlatform? platform,
    Object? device = _unset,
    Object? osVersion = _unset,
    Object? appVersion = _unset,
    Object? logs = _unset,
    Object? severity = _unset,
    Object? priority = _unset,
    BugStatus? status,
    List<String>? reproductionSteps,
    List<BugTestCase>? testCases,
    Object? possibleRootCause = _unset,
    Object? rootCauseConfidence = _unset,
    Object? screenshot = _unset,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BugReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      expectedBehavior: expectedBehavior ?? this.expectedBehavior,
      actualBehavior: actualBehavior ?? this.actualBehavior,
      platform: platform ?? this.platform,
      device: identical(device, _unset) ? this.device : device as String?,
      osVersion: identical(osVersion, _unset)
          ? this.osVersion
          : osVersion as String?,
      appVersion: identical(appVersion, _unset)
          ? this.appVersion
          : appVersion as String?,
      logs: identical(logs, _unset) ? this.logs : logs as String?,
      severity: identical(severity, _unset)
          ? this.severity
          : severity as BugSeverity?,
      priority: identical(priority, _unset)
          ? this.priority
          : priority as BugPriority?,
      status: status ?? this.status,
      reproductionSteps: reproductionSteps ?? this.reproductionSteps,
      testCases: testCases ?? this.testCases,
      possibleRootCause: identical(possibleRootCause, _unset)
          ? this.possibleRootCause
          : possibleRootCause as String?,
      rootCauseConfidence: identical(rootCauseConfidence, _unset)
          ? this.rootCauseConfidence
          : rootCauseConfidence as double?,
      screenshot: identical(screenshot, _unset)
          ? this.screenshot
          : screenshot as BugScreenshot?,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'platform': platform.jsonValue,
      'device': device,
      'osVersion': osVersion,
      'appVersion': appVersion,
      'logs': logs,
      'severity': severity?.jsonValue,
      'priority': priority?.jsonValue,
      'status': status.jsonValue,
      'reproductionSteps': reproductionSteps,
      'testCases': testCases.map((testCase) => testCase.toJson()).toList(),
      'possibleRootCause': possibleRootCause,
      'rootCauseConfidence': rootCauseConfidence,
      'screenshot': screenshot?.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is BugReport &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            description == other.description &&
            expectedBehavior == other.expectedBehavior &&
            actualBehavior == other.actualBehavior &&
            platform == other.platform &&
            device == other.device &&
            osVersion == other.osVersion &&
            appVersion == other.appVersion &&
            logs == other.logs &&
            severity == other.severity &&
            priority == other.priority &&
            status == other.status &&
            _listEquals(reproductionSteps, other.reproductionSteps) &&
            _listEquals(testCases, other.testCases) &&
            possibleRootCause == other.possibleRootCause &&
            rootCauseConfidence == other.rootCauseConfidence &&
            screenshot == other.screenshot &&
            createdAt == other.createdAt &&
            updatedAt == other.updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      expectedBehavior,
      actualBehavior,
      platform,
      device,
      osVersion,
      appVersion,
      logs,
      severity,
      priority,
      status,
      Object.hashAll(reproductionSteps),
      Object.hashAll(testCases),
      possibleRootCause,
      rootCauseConfidence,
      screenshot,
      createdAt,
      updatedAt,
    );
  }
}

bool _listEquals<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }

  if (first.length != second.length) {
    return false;
  }

  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }

  return true;
}
