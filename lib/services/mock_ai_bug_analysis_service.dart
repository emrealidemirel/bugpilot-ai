import 'package:bugpilot_ai/models/bug_priority.dart';
import 'package:bugpilot_ai/models/bug_severity.dart';
import 'package:bugpilot_ai/models/bug_test_case_type.dart';
import 'package:bugpilot_ai/models/bug_report.dart';
import 'package:bugpilot_ai/models/bug_test_case.dart';
import 'package:bugpilot_ai/models/ai_analysis_preferences.dart';
import 'package:bugpilot_ai/models/ai_bug_analysis.dart';
import 'package:bugpilot_ai/services/ai_bug_analysis_service.dart';

class MockAiBugAnalysisService implements AiBugAnalysisService {
  const MockAiBugAnalysisService({
    this.delay = const Duration(milliseconds: 450),
  });

  final Duration delay;

  @override
  Future<AiBugAnalysis> analyze(
    BugReport bug, {
    AiAnalysisPreferences preferences = AiAnalysisPreferences.defaults,
    String languageCode = 'en',
  }) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final isTurkish = languageCode == 'tr';

    return AiBugAnalysis(
      severity: preferences.severity ? BugSeverity.high : null,
      severityReason: preferences.severity
          ? isTurkish
                ? 'Sorun önemli bir kullanıcı akışını engelliyor ve beklenen işlemin tamamlanmasını önlüyor.'
                : 'The issue blocks an important user flow and prevents successful completion of the expected action.'
          : null,
      priority: preferences.priority ? BugPriority.p1 : null,
      priorityReason: preferences.priority
          ? isTurkish
                ? 'Sorun temel bir iş akışını etkiliyor ve yüksek öncelikli bir sonraki geliştirme döngüsünde ele alınmalı.'
                : 'The issue affects a core workflow and should be addressed in the next high-priority development cycle.'
          : null,
      reproductionSteps: isTurkish
          ? const [
              'Uygulamayı açın',
              'Etkilenen ekrana gidin',
              'Hata raporunda açıklanan işlemi yapın',
              'Beklenmeyen davranışı gözlemleyin',
              'Sorunun tekrarlanabildiğini doğrulamak için işlemi yineleyin',
            ]
          : const [
              'Open the application',
              'Navigate to the affected screen',
              'Perform the action described in the bug report',
              'Observe the unexpected behavior',
              'Repeat the action to verify the issue is reproducible',
            ],
      testCases: preferences.testCases
          ? _testCases(isTurkish: isTurkish)
          : const [],
      possibleRootCause: preferences.rootCause
          ? isTurkish
                ? 'Asenkron işlem tamamlandıktan sonra arayüz durumu doğru güncellenmiyor olabilir; bu da ekranı hatalı durumda bırakabilir.'
                : 'The UI state may not be updated correctly after the asynchronous operation completes, leaving the screen in an incorrect state.'
          : null,
      rootCauseConfidence: preferences.rootCause ? 0.72 : null,
      missingInformation: _missingInformationFor(bug, isTurkish: isTurkish),
      qualityScore: _qualityScoreFor(bug),
    );
  }

  List<String> _missingInformationFor(
    BugReport bug, {
    required bool isTurkish,
  }) {
    final missing = <String>[];

    if (_isBlank(bug.device)) {
      missing.add(
        isTurkish
            ? 'Cihaz modeli belirtilmemiş.'
            : 'Device model was not provided.',
      );
    }
    if (_isBlank(bug.appVersion)) {
      missing.add(
        isTurkish
            ? 'Uygulama sürümü belirtilmemiş.'
            : 'App version was not provided.',
      );
    }
    if (_isBlank(bug.logs)) {
      missing.add(
        isTurkish
            ? 'Hata günlükleri eklenmemiş.'
            : 'Error logs were not provided.',
      );
    }

    return missing;
  }

  int _qualityScoreFor(BugReport bug) {
    var score = 0;

    if (bug.title.trim().isNotEmpty) {
      score += 15;
    }
    if (bug.description.trim().length >= 20) {
      score += 20;
    } else if (bug.description.trim().isNotEmpty) {
      score += 10;
    }
    if (bug.expectedBehavior.trim().isNotEmpty) {
      score += 15;
    }
    if (bug.actualBehavior.trim().isNotEmpty) {
      score += 15;
    }
    if (!_isBlank(bug.device)) {
      score += 10;
    }
    if (!_isBlank(bug.appVersion)) {
      score += 10;
    }
    if (!_isBlank(bug.logs)) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  bool _isBlank(String? value) {
    return value == null || value.trim().isEmpty;
  }
}

List<BugTestCase> _testCases({required bool isTurkish}) => [
  BugTestCase(
    id: 'TC-01',
    type: BugTestCaseType.positive,
    title: isTurkish
        ? 'Beklenen akış başarıyla tamamlanır'
        : 'Expected flow completes successfully',
    given: isTurkish
        ? 'Kullanıcı etkilenen ekranda ve geçerli bilgileri hazır'
        : 'A user is on the affected screen with valid inputs ready',
    when: isTurkish
        ? 'Beklenen işlem gerçekleştirilir'
        : 'The expected action is performed',
    then: isTurkish
        ? 'Uygulama takılmadan beklenen akışı tamamlamalıdır'
        : 'The application should complete the expected flow without becoming stuck',
  ),
  BugTestCase(
    id: 'TC-02',
    type: BugTestCaseType.negative,
    title: isTurkish
        ? 'İşlem geçersiz bilgileri doğru şekilde ele alır'
        : 'Operation handles invalid input correctly',
    given: isTurkish
        ? 'Kullanıcı etkilenen ekranda geçersiz veya eksik bilgilerle bulunur'
        : 'A user is on the affected screen with invalid or missing data',
    when: isTurkish
        ? 'Bildirilen işlem denenir'
        : 'The reported action is attempted',
    then: isTurkish
        ? 'Uygulama açık bir hata göstermeli ve kurtarılabilir durumda kalmalıdır'
        : 'The application should show a clear error and preserve a recoverable state',
  ),
  BugTestCase(
    id: 'TC-03',
    type: BugTestCaseType.edgeCase,
    title: isTurkish
        ? 'İşlemin tekrarlanması arayüzü tutarsız bırakmaz'
        : 'Repeated action does not leave the UI in an inconsistent state',
    given: isTurkish
        ? 'Kullanıcı etkilenen işlemi art arda başlatabilir'
        : 'A user can repeatedly trigger the affected action',
    when: isTurkish
        ? 'İşlem kısa aralıklarla birkaç kez yapılır'
        : 'The action is performed several times in quick succession',
    then: isTurkish
        ? 'Arayüz tutarlı kalmalı ve yalnızca son işlemin durumunu göstermelidir'
        : 'The UI should remain consistent and show only the latest operation state',
  ),
];
