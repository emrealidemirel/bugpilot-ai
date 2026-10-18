import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:bugpilot_ai/models/similar_bug_candidate.dart';
import 'package:bugpilot_ai/services/bug_duplicate_detection_service.dart';

class MockBugDuplicateDetectionService implements BugDuplicateDetectionService {
  const MockBugDuplicateDetectionService({
    this.delay = const Duration(milliseconds: 150),
  });

  final Duration delay;

  @override
  Future<DuplicateCheckResult> checkDuplicates({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
    String languageCode = 'en',
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }

    return DuplicateCheckResult(
      matches: [
        for (final candidate in candidates)
          DuplicateMatch(
            bugId: candidate.bug.id,
            similarity: candidate.localScore >= 0.55
                ? DuplicateSimilarity.likelyDuplicate
                : DuplicateSimilarity.related,
            confidence: candidate.localScore.clamp(0.35, 0.92),
            reason: languageCode == 'tr'
                ? 'Bu raporun başlığı veya gözlemlenen davranışı mevcut bir hatayla örtüşüyor.'
                : 'This report overlaps with the title or observed behavior of an existing local bug.',
          ),
      ],
    );
  }
}
