import '../../../bug_reports/domain/models/bug_report.dart';
import '../models/similar_bug_candidate.dart';

class LocalBugSimilarityService {
  const LocalBugSimilarityService({
    this.threshold = 0.30,
    this.maxCandidates = 5,
  }) : assert(threshold >= 0 && threshold <= 1),
       assert(maxCandidates > 0);

  final double threshold;
  final int maxCandidates;

  List<SimilarBugCandidate> findCandidates({
    required BugReport draft,
    required List<BugReport> existingBugs,
  }) {
    final candidates = <SimilarBugCandidate>[];

    for (final bug in existingBugs) {
      if (bug.id == draft.id) {
        continue;
      }

      final localScore = score(draft: draft, existing: bug);
      if (localScore >= threshold) {
        candidates.add(SimilarBugCandidate(bug: bug, localScore: localScore));
      }
    }

    candidates.sort((a, b) {
      final scoreComparison = b.localScore.compareTo(a.localScore);
      if (scoreComparison != 0) {
        return scoreComparison;
      }

      final createdComparison = b.bug.createdAt.compareTo(a.bug.createdAt);
      if (createdComparison != 0) {
        return createdComparison;
      }

      return a.bug.id.compareTo(b.bug.id);
    });

    return List.unmodifiable(candidates.take(maxCandidates));
  }

  double score({required BugReport draft, required BugReport existing}) {
    // Weighted Jaccard similarity emphasizes user-visible symptoms. Platform is
    // a modest boost, not a hard gate, so shared cross-platform bugs can surface.
    final title = _jaccard(_tokens(draft.title), _tokens(existing.title));
    final actualBehavior = _jaccard(
      _tokens(draft.actualBehavior),
      _tokens(existing.actualBehavior),
    );
    final description = _jaccard(
      _tokens(draft.description),
      _tokens(existing.description),
    );
    final expectedBehavior = _jaccard(
      _tokens(draft.expectedBehavior),
      _tokens(existing.expectedBehavior),
    );
    final platform = draft.platform == existing.platform ? 1.0 : 0.0;
    final severity =
        draft.severity != null &&
            existing.severity != null &&
            draft.severity == existing.severity
        ? 1.0
        : 0.0;

    return (title * 0.42) +
        (actualBehavior * 0.25) +
        (description * 0.18) +
        (expectedBehavior * 0.08) +
        (platform * 0.05) +
        (severity * 0.02);
  }

  Set<String> _tokens(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s']+"), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (normalized.isEmpty) {
      return const {};
    }

    return normalized
        .split(' ')
        .where((token) => token.length >= 3 && !_stopWords.contains(token))
        .toSet();
  }

  double _jaccard(Set<String> first, Set<String> second) {
    if (first.isEmpty || second.isEmpty) {
      return 0;
    }

    final intersection = first.intersection(second).length;
    if (intersection == 0) {
      return 0;
    }

    return intersection / first.union(second).length;
  }
}

const _stopWords = {
  'the',
  'and',
  'for',
  'with',
  'that',
  'this',
  'from',
  'when',
  'then',
  'should',
  'would',
  'could',
  'into',
  'onto',
  'after',
  'before',
  'user',
  'users',
  'app',
  'application',
  'error',
  'issue',
  'bug',
  'screen',
  'page',
};
