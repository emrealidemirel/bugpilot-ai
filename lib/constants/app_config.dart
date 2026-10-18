abstract final class AppConfig {
  static const String openAiApiKey = String.fromEnvironment('OPENAI_API_KEY');
  static const String openAiModel = String.fromEnvironment(
    'OPENAI_MODEL',
    defaultValue: 'gpt-5.6-terra',
  );

  static const bool forceMockAi = bool.fromEnvironment('USE_MOCK_AI');
  static const bool useMockAi = forceMockAi || openAiApiKey == '';

  static const Duration aiAnalysisTimeout = Duration(seconds: 60);

  static const Duration duplicateCheckTimeout = Duration(seconds: 20);
}
