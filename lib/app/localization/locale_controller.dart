import 'package:flutter/material.dart';

class LocaleController extends ChangeNotifier {
  LocaleController({Locale? initialLocale})
    : _locale = _resolveSupportedLocale(initialLocale ?? const Locale('en'));

  static const supportedLocales = [Locale('en'), Locale('tr')];

  Locale _locale;

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    final supportedLocale = _resolveSupportedLocale(locale);

    if (_locale == supportedLocale) {
      return;
    }

    _locale = supportedLocale;
    notifyListeners();
  }

  static Locale _resolveSupportedLocale(Locale locale) {
    return supportedLocales.firstWhere(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
      orElse: () => const Locale('en'),
    );
  }
}
