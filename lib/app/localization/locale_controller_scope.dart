import 'package:flutter/widgets.dart';

import 'locale_controller.dart';

class LocaleControllerScope extends InheritedNotifier<LocaleController> {
  const LocaleControllerScope({
    required LocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static LocaleController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<LocaleControllerScope>();

    assert(scope != null, 'No LocaleControllerScope found in context.');
    return scope!.notifier!;
  }
}
