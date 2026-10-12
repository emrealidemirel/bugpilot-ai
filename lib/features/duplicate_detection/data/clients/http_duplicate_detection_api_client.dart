import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../ai_analysis/data/exceptions/ai_analysis_exception.dart';
import '../../../ai_analysis/data/models/ai_api_error.dart';
import '../models/duplicate_check_request.dart';
import '../../domain/models/duplicate_check_result.dart';
import 'duplicate_detection_api_client.dart';

class HttpDuplicateDetectionApiClient implements DuplicateDetectionApiClient {
  HttpDuplicateDetectionApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final http.Client _httpClient;

  @override
  Future<DuplicateCheckResult> checkDuplicates(
    DuplicateCheckRequest request,
  ) async {
    try {
      final response = await _httpClient
          .post(
            _endpointUri(),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(timeout);

      final decoded = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return DuplicateCheckResult.fromJson(decoded);
      }

      throw AiAnalysisException.fromApiError(AiApiError.fromJson(decoded));
    } on AiAnalysisException {
      rethrow;
    } on TimeoutException {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.requestTimeout,
        message: 'The duplicate check request timed out.',
      );
    } on SocketException {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.networkError,
        message: 'Could not connect to the duplicate check backend.',
      );
    } on FormatException catch (error) {
      throw AiAnalysisException(
        code: AiAnalysisErrorCode.aiResponseInvalid,
        message: error.message,
      );
    } on ArgumentError catch (error) {
      throw AiAnalysisException(
        code: AiAnalysisErrorCode.aiResponseInvalid,
        message: error.message,
      );
    } on Object {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.unknownError,
        message: 'Something went wrong while checking for duplicates.',
      );
    }
  }

  Uri _endpointUri() {
    final normalizedBasePath = baseUrl.path.endsWith('/')
        ? baseUrl.path.substring(0, baseUrl.path.length - 1)
        : baseUrl.path;

    return baseUrl.replace(
      path: '$normalizedBasePath/api/v1/ai/check-duplicates',
    );
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'Duplicate check response must be a JSON object.',
      );
    }

    return decoded;
  }
}
