import '../models/duplicate_check_request.dart';
import '../../domain/models/duplicate_check_result.dart';

abstract class DuplicateDetectionApiClient {
  Future<DuplicateCheckResult> checkDuplicates(DuplicateCheckRequest request);
}
