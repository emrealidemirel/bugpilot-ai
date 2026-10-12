import '../../../bug_reports/domain/enums/bug_priority.dart';
import '../../../bug_reports/domain/enums/bug_severity.dart';
import '../../../bug_reports/domain/enums/bug_test_case_type.dart';
import '../../../bug_reports/domain/models/bug_report.dart';
import '../../../bug_reports/domain/models/bug_test_case.dart';
import '../../domain/models/ai_analysis_preferences.dart';
import '../../domain/models/ai_bug_analysis.dart';
import '../../domain/services/ai_bug_analysis_service.dart';

class MockAiBugAnalysisService implements AiBugAnalysisService {
  const MockAiBugAnalysisService({
    this.delay = const Duration(milliseconds: 450),
  });

  final Duration delay;

  @override
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    return AiBugAnalysis(
      severity: preferences.severity ? BugSeverity.high : null,
      severityReason: preferences.severity
          ? 'The issue blocks an important user flow and prevents successful '
                'completion of the expected action.'
          : null,
      priority: preferences.priority ? BugPriority.p1 : null,
      priorityReason: preferences.priority
          ? 'The issue affects a core workflow and should be addressed in the '
                'next high-priority development cycle.'
          : null,
      reproductionSteps: const [
        'Open the application',
        'Navigate to the affected screen',
        'Perform the action described in the bug report',
        'Observe the unexpected behavior',
        'Repeat the action to verify the issue is reproducible',
      ],
      testCases: preferences.testCases ? _testCases : const [],
      possibleRootCause: preferences.rootCause
          ? 'The UI state may not be updated correctly after the asynchronous '
                'operation completes, leaving the screen in an incorrect state.'
          : null,
      rootCauseConfidence: preferences.rootCause ? 0.72 : null,
      missingInformation: _missingInformationFor(bug),
      qualityScore: _qualityScoreFor(bug),
    );
  }

  List<String> _missingInformationFor(BugReport bug) {
    final missing = <String>[];

    if (_isBlank(bug.device)) {
      missing.add('Device model was not provided.');
    }
    if (_isBlank(bug.appVersion)) {
      missing.add('App version was not provided.');
    }
    if (_isBlank(bug.logs)) {
      missing.add('Error logs were not provided.');
    }

    return missing;
  }

  int _qualityScoreFor(BugReport bug) {
    var score = 0;

    if (bug.title.trim().isNotEmpty) {
      score += 15;
    }
    if (bug.description.trim().length >= 20) {
      score += 20;
    } else if (bug.description.trim().isNotEmpty) {
      score += 10;
    }
    if (bug.expectedBehavior.trim().isNotEmpty) {
      score += 15;
    }
    if (bug.actualBehavior.trim().isNotEmpty) {
      score += 15;
    }
    if (!_isBlank(bug.device)) {
      score += 10;
    }
    if (!_isBlank(bug.appVersion)) {
      score += 10;
    }
    if (!_isBlank(bug.logs)) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }
}

const _testCases = [
  BugTestCase(
    id: 'TC-01',
    type: BugTestCaseType.positive,
    title: 'Expected flow completes successfully',
    given: 'A user is on the affected screen with valid inputs ready',
    when: 'The expected action is performed',
    then:
        'The application should complete the expected flow without '
        'becoming stuck',
  ),
  BugTestCase(
    id: 'TC-02',
    type: BugTestCaseType.negative,
    title: 'Operation handles invalid input correctly',
    given: 'A user is on the affected screen with invalid or missing data',
    when: 'The reported action is attempted',
    then:
        'The application should show a clear error and preserve a '
        'recoverable state',
  ),
  BugTestCase(
    id: 'TC-03',
    type: BugTestCaseType.edgeCase,
    title: 'Repeated action does not leave the UI in an inconsistent state',
    given: 'A user can repeatedly trigger the affected action',
    when: 'The action is performed several times in quick succession',
    then:
        'The UI should remain consistent and show only the latest operation state',
  ),
];
