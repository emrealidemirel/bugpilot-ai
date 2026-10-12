// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'BugPilot AI';

  @override
  String get dashboardNavLabel => 'Panel';

  @override
  String get bugsNavLabel => 'Hatalar';

  @override
  String get reportNavLabel => 'Bildir';

  @override
  String get settingsNavLabel => 'Ayarlar';

  @override
  String get dashboardTitle => 'Panel';

  @override
  String get dashboardDescription =>
      'Hata raporlama özetiniz burada görünecek.';

  @override
  String get dashboardSubtitle => 'AI destekli hata önceliklendirme';

  @override
  String get dashboardGreeting => 'İyi günler';

  @override
  String get dashboardGreetingMessage => 'Birkaç hatayı birlikte çözelim.';

  @override
  String get totalBugsStatLabel => 'Toplam Hata';

  @override
  String get openStatLabel => 'Açık';

  @override
  String get criticalStatLabel => 'Kritik';

  @override
  String get resolvedStatLabel => 'Çözüldü';

  @override
  String get recentBugsTitle => 'Son Hatalar';

  @override
  String get viewAllAction => 'Tümünü gör';

  @override
  String get reportBugAction => 'Hata Bildir';

  @override
  String get bugReportsTitle => 'Hatalar';

  @override
  String get bugReportsDescription =>
      'Kaydedilen raporları ve mevcut durumları takip edin.';

  @override
  String get emptyBugReportsMessage => 'Henüz hata raporu yok.';

  @override
  String get reportBugTitle => 'Hata Bildir';

  @override
  String get reportBugDescription =>
      'Sorunu açıklayın; AI analizde yardımcı olacak.';

  @override
  String get issueSectionTitle => 'Sorun';

  @override
  String get behaviorSectionTitle => 'Davranış';

  @override
  String get environmentSectionTitle => 'Ortam';

  @override
  String get technicalDetailsSectionTitle => 'Teknik Detaylar';

  @override
  String get bugTitleFieldLabel => 'Hata Başlığı';

  @override
  String get bugTitleFieldHint =>
      'Örnek: Giriş bilgileri gönderilince buton takılı kalıyor';

  @override
  String get descriptionFieldLabel => 'Açıklama';

  @override
  String get descriptionFieldHint => 'Ne olduğunu açıklayın...';

  @override
  String get expectedBehaviorFieldLabel => 'Beklenen Davranış';

  @override
  String get expectedBehaviorFieldHint => 'Ne olmalıydı?';

  @override
  String get actualBehaviorFieldLabel => 'Gerçekleşen Davranış';

  @override
  String get actualBehaviorFieldHint => 'Gerçekte ne oldu?';

  @override
  String get platformFieldLabel => 'Platform';

  @override
  String get deviceFieldLabel => 'Cihaz';

  @override
  String get deviceFieldHint => 'Pixel 9, iPhone 16, Chrome Desktop';

  @override
  String get osVersionFieldLabel => 'OS Sürümü';

  @override
  String get osVersionFieldHint => 'Örnek: Android 16';

  @override
  String get appVersionFieldLabel => 'Uygulama Sürümü';

  @override
  String get appVersionFieldHint => 'Örnek: 1.0.0';

  @override
  String get logsFieldLabel => 'Hata Logları / Stack Trace';

  @override
  String get logsFieldHint =>
      'Hata loglarını veya stack trace\'i buraya yapıştırın...';

  @override
  String get saveBugReportAction => 'Hata Raporunu Kaydet';

  @override
  String get savingBugReportAction => 'Kaydediliyor...';

  @override
  String get bugReportCreatedMessage => 'Hata raporu başarıyla oluşturuldu.';

  @override
  String get bugReportCreateErrorMessage =>
      'Hata raporu oluşturulamadı. Lütfen tekrar deneyin.';

  @override
  String get requiredFieldValidation => 'Bu alan zorunludur.';

  @override
  String get platformRequiredValidation => 'Bir platform seçin.';

  @override
  String get bugTitleMinValidation => 'En az 5 karakter girin.';

  @override
  String get bugTitleMaxValidation => 'Başlığı 120 karakterin altında tutun.';

  @override
  String get descriptionMinValidation => 'En az 10 karakter girin.';

  @override
  String get optionalMaxValidation => 'Bu alanı 80 karakterin altında tutun.';

  @override
  String get appVersionMaxValidation => 'Bu alanı 40 karakterin altında tutun.';

  @override
  String get discardReportTitle => 'Rapor silinsin mi?';

  @override
  String get discardReportMessage =>
      'Kaydedilmemiş değişiklikleriniz kaybolacak.';

  @override
  String get keepEditingAction => 'Düzenlemeye Devam Et';

  @override
  String get discardAction => 'Sil';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsDescription =>
      'Çalışma alanı ve uygulama tercihleri burada görünecek.';

  @override
  String get languageSectionTitle => 'Dil';

  @override
  String get languageSectionDescription => 'BugPilot AI arayüz dilini seçin.';

  @override
  String get englishLanguage => 'English';

  @override
  String get turkishLanguage => 'Türkçe';
}
