import 'package:bugpilot_ai/models/bug_report.dart';

class SimilarBugCandidate {
  const SimilarBugCandidate({required this.bug, required this.localScore});

  final BugReport bug;
  final double localScore;
}
