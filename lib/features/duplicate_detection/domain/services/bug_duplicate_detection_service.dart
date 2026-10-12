import '../../../bug_reports/domain/models/bug_report.dart';
import '../models/duplicate_check_result.dart';
import '../models/similar_bug_candidate.dart';

abstract class BugDuplicateDetectionService {
  Future<DuplicateCheckResult> checkDuplicates({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
  });
}
