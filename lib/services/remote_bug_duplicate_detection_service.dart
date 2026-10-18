import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';
import 'package:bugpilot_ai/models/similar_bug_candidate.dart';
import 'package:bugpilot_ai/services/bug_duplicate_detection_service.dart';
import 'package:bugpilot_ai/services/duplicate_detection_api_client.dart';
import 'package:bugpilot_ai/models/duplicate_check_request.dart';

class RemoteBugDuplicateDetectionService
    implements BugDuplicateDetectionService {
  const RemoteBugDuplicateDetectionService({required this.apiClient});

  final DuplicateDetectionApiClient apiClient;

  @override
  Future<DuplicateCheckResult> checkDuplicates({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
    String languageCode = 'en',
  }) {
    return apiClient.checkDuplicates(
      DuplicateCheckRequest.fromBugReport(
        draft: draft,
        candidates: candidates,
        languageCode: languageCode,
      ),
    );
  }
}
