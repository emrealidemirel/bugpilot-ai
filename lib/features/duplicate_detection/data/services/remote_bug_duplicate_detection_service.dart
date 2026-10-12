import '../../../bug_reports/domain/models/bug_report.dart';
import '../../domain/models/duplicate_check_result.dart';
import '../../domain/models/similar_bug_candidate.dart';
import '../../domain/services/bug_duplicate_detection_service.dart';
import '../clients/duplicate_detection_api_client.dart';
import '../models/duplicate_check_request.dart';

class RemoteBugDuplicateDetectionService
    implements BugDuplicateDetectionService {
  const RemoteBugDuplicateDetectionService({required this.apiClient});

  final DuplicateDetectionApiClient apiClient;

  @override
  Future<DuplicateCheckResult> checkDuplicates({
    required BugReport draft,
    required List<SimilarBugCandidate> candidates,
  }) {
    return apiClient.checkDuplicates(
      DuplicateCheckRequest.fromBugReport(draft: draft, candidates: candidates),
    );
  }
}
