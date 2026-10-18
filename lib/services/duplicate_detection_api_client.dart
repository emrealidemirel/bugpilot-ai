import 'package:bugpilot_ai/models/duplicate_check_request.dart';
import 'package:bugpilot_ai/models/duplicate_check_result.dart';

abstract class DuplicateDetectionApiClient {
  Future<DuplicateCheckResult> checkDuplicates(DuplicateCheckRequest request);
}
