import '../../../bug_reports/domain/enums/bug_platform.dart';
import '../../../bug_reports/domain/enums/bug_severity.dart';
import '../../../bug_reports/domain/enums/bug_status.dart';
import '../../../bug_reports/domain/models/bug_report.dart';
import '../../domain/models/similar_bug_candidate.dart';

class DuplicateCheckRequest {
  DuplicateCheckRequest({
    required this.bug,
    required List<DuplicateCandidateRequest> candidates,
  }) : candidates = List.unmodifiable(candidates);

  factory DuplicateCheckRequest.fromBugReport({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
  }) {
    return DuplicateCheckRequest(
      bug: DuplicateDraftBugRequest.fromBugReport(draft),
      candidates: candidates
          .map(
            (candidate) =>
                DuplicateCandidateRequest.fromBugReport(candidate.bug),
          )
          .toList(),
    );
  }

  final DuplicateDraftBugRequest bug;
  final List<DuplicateCandidateRequest> candidates;

  Map<String, dynamic> toJson() {
    return {
      'bug': bug.toJson(),
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
    };
  }
}

class DuplicateDraftBugRequest {
  const DuplicateDraftBugRequest({
    required this.title,
    required this.description,
    required this.expectedBehavior,
    required this.actualBehavior,
    required this.platform,
  });

  factory DuplicateDraftBugRequest.fromBugReport(BugReport bug) {
    return DuplicateDraftBugRequest(
      title: bug.title,
      description: bug.description,
      expectedBehavior: bug.expectedBehavior,
      actualBehavior: bug.actualBehavior,
      platform: bug.platform.jsonValue,
    );
  }

  final String title;
  final String description;
  final String expectedBehavior;
  final String actualBehavior;
  final String platform;

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'expectedBehavior': expectedBehavior,
      'actualBehavior': actualBehavior,
      'platform': platform,
    };
  }
}

class DuplicateCandidateRequest extends DuplicateDraftBugRequest {
  const DuplicateCandidateRequest({
    required this.id,
    required super.title,
    required super.description,
    required super.expectedBehavior,
    required super.actualBehavior,
    required super.platform,
    this.severity,
    required this.status,
  });

  factory DuplicateCandidateRequest.fromBugReport(BugReport bug) {
    return DuplicateCandidateRequest(
      id: bug.id,
      title: bug.title,
      description: bug.description,
      expectedBehavior: bug.expectedBehavior,
      actualBehavior: bug.actualBehavior,
      platform: bug.platform.jsonValue,
      severity: bug.severity?.jsonValue,
      status: bug.status.jsonValue,
    );
  }

  final String id;
  final String? severity;
  final String status;

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      ...super.toJson(),
      if (_hasValue(severity)) 'severity': severity,
      'status': status,
    };
  }
}

bool _hasValue(String? value) {
  return value != null && value.trim().isNotEmpty;
}
