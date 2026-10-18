import 'package:bugpilot_ai/models/bug_report.dart';

abstract class BugRepository {
  Future<List<BugReport>> getBugs();

  Future<BugReport?> getBugById(String id);

  Future<void> createBug(BugReport bug);

  Future<void> updateBug(BugReport bug);

  Future<void> deleteBug(String id);
}
