import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:bugpilot_ai/models/similar_bug_candidate.dart';

abstract class BugDuplicateDetectionService {
  Future<DuplicateCheckResult> checkDuplicates({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
    String languageCode = 'en',
  });
}
