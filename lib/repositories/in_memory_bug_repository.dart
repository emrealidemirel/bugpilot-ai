import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/repositories/bug_repository.dart';

class InMemoryBugRepository implements BugRepository {
  InMemoryBugRepository({List<BugReport>? seedBugs})
    : _bugs = List.of(seedBugs ?? const []);

  final List<BugReport> _bugs;

  @override
  Future<List<BugReport>> getBugs() async {
    return List.unmodifiable(_bugs);
  }

  @override
  Future<BugReport?> getBugById(String id) async {
    for (final bug in _bugs) {
      if (bug.id == id) {
        return bug;
      }
    }

    return null;
  }

  @override
  Future<void> createBug(BugReport bug) async {
    final alreadyExists = _bugs.any((existingBug) => existingBug.id == bug.id);
    if (alreadyExists) {
      throw StateError('A bug with id "${bug.id}" already exists.');
    }

    _bugs.add(bug);
  }

  @override
  Future<void> updateBug(BugReport bug) async {
    final index = _bugs.indexWhere((existingBug) => existingBug.id == bug.id);
    if (index == -1) {
      throw StateError('Cannot update missing bug with id "${bug.id}".');
    }

    _bugs[index] = bug;
  }

  @override
  Future<void> deleteBug(String id) async {
    _bugs.removeWhere((bug) => bug.id == id);
  }
}
