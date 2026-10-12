abstract final class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  static const bool useMockAi = bool.fromEnvironment('USE_MOCK_AI');

  static const Duration aiAnalysisTimeout = Duration(seconds: 60);

  static const Duration duplicateCheckTimeout = Duration(seconds: 20);
}
