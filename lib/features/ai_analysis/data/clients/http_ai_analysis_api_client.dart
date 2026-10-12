import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../bug_reports/domain/models/bug_screenshot.dart';
import '../exceptions/ai_analysis_exception.dart';
import '../models/ai_analysis_request.dart';
import '../models/ai_analysis_response.dart';
import '../models/ai_api_error.dart';
import 'ai_analysis_api_client.dart';

class HttpAiAnalysisApiClient implements AiAnalysisApiClient {
  HttpAiAnalysisApiClient({
    required this.baseUrl,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 45),
  }) : _httpClient = httpClient ?? http.Client();

  final Uri baseUrl;
  final Duration timeout;
  final http.Client _httpClient;

  @override
  Future<AiAnalysisResponse> analyze(
    AiAnalysisRequest request, {
    BugScreenshot? screenshot,
  }) async {
    try {
      final response = screenshot == null
          ? await _postJson(request).timeout(timeout)
          : await _postMultipart(request, screenshot).timeout(timeout);

      final decoded = _decodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AiAnalysisResponse.fromJson(decoded);
      }

      throw AiAnalysisException.fromApiError(AiApiError.fromJson(decoded));
    } on AiAnalysisException {
      rethrow;
    } on TimeoutException {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.requestTimeout,
        message: 'The analysis request timed out.',
      );
    } on SocketException {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.networkError,
        message: 'Could not connect to the AI analysis backend.',
      );
    } on FileSystemException {
      throw const AiAnalysisException(
        code: AiAnalysisErrorCode.screenshotUploadFailed,
        message: 'The screenshot could not be uploaded for analysis.',
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
        message: 'Something went wrong while analyzing this bug report.',
      );
    }
  }

  Future<http.Response> _postJson(AiAnalysisRequest request) {
    return _httpClient.post(
      _endpointUri(),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(request.toJson()),
    );
  }

  Future<http.Response> _postMultipart(
    AiAnalysisRequest request,
    BugScreenshot screenshot,
  ) async {
    final multipart = http.MultipartRequest('POST', _endpointUri())
      ..fields['bug'] = jsonEncode(request.toJson())
      ..files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshot.localPath,
          filename: screenshot.fileName,
          contentType: MediaType.parse(screenshot.mimeType),
        ),
      );

    final streamed = await _httpClient.send(multipart);
    return http.Response.fromStream(streamed);
  }

  Uri _endpointUri() {
    final normalizedBasePath = baseUrl.path.endsWith('/')
        ? baseUrl.path.substring(0, baseUrl.path.length - 1)
        : baseUrl.path;

    return baseUrl.replace(path: '$normalizedBasePath/api/v1/ai/analyze-bug');
  }

  Map<String, dynamic> _decodeObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException(
        'AI analysis response must be a JSON object.',
      );
    }

    return decoded;
  }
}
