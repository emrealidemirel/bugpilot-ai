import 'package:flutter/foundation.dart';

abstract final class AppConfig {
  static const String openAiApiKey = kDebugMode
      ? String.fromEnvironment('OPENAI_API_KEY')
      : '';
  static const String privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
  );
  static const bool appleSignInEnabled = bool.fromEnvironment(
    'APPLE_SIGN_IN_ENABLED',
  );
  static const String openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-5.6-terra',
  );

  static const Duration aiAnalysisTimeout = Duration(seconds: 60);

  static const Duration duplicateCheckTimeout = Duration(seconds: 20);
}
