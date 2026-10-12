import 'package:flutter/widgets.dart';

import '../../../../app/localization/localization_extensions.dart';

abstract final class BugFormValidators {
  static String? title(BuildContext context, String? value) {
    final l10n = context.l10n;
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return l10n.requiredFieldValidation;
    }
    if (trimmedValue.length < 5) {
      return l10n.bugTitleMinValidation;
    }
    if (trimmedValue.length > 120) {
      return l10n.bugTitleMaxValidation;
    }

    return null;
  }

  static String? description(BuildContext context, String? value) {
    final l10n = context.l10n;
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return l10n.requiredFieldValidation;
    }
    if (trimmedValue.length < 10) {
      return l10n.descriptionMinValidation;
    }

    return null;
  }

  static String? requiredText(BuildContext context, String? value) {
    if ((value?.trim() ?? '').isEmpty) {
      return context.l10n.requiredFieldValidation;
    }

    return null;
  }

  static String? optionalMax(BuildContext context, String? value) {
    if ((value?.trim().length ?? 0) > 80) {
      return context.l10n.optionalMaxValidation;
    }

    return null;
  }

  static String? appVersion(BuildContext context, String? value) {
    if ((value?.trim().length ?? 0) > 40) {
      return context.l10n.appVersionMaxValidation;
    }

    return null;
  }
}
