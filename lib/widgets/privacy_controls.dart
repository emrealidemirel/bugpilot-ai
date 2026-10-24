import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:bugpilot_ai/constants/app_config.dart';
import 'auth_service_scope.dart';

Future<bool> requestAiConsent(BuildContext context) async {
  final scope = AuthServiceScope.maybeOf(context);
  // Standalone previews and tests may not have an authenticated application.
  if (scope?.service == null) return true;
  if (scope?.user?.emailVerified != true) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('verifyEmailBeforeAi'.tr())));
    return false;
  }
  if (scope?.aiConsent?.accepted == true) return true;
  final uid = scope?.user?.id;
  final accepted = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('aiConsentTitle'.tr()),
      content: SingleChildScrollView(child: Text('aiConsentDescription'.tr())),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('cancelAction'.tr()),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('aiConsentAccept'.tr()),
        ),
      ],
    ),
  );
  if (!context.mounted || AuthServiceScope.maybeOf(context)?.user?.id != uid) {
    return false;
  }
  if (accepted == true) scope?.aiConsent?.accepted = true;
  return accepted == true;
}

Future<void> showPrivacyInformation(
  BuildContext context,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.75,
    minChildSize: 0.4,
    maxChildSize: 0.95,
    builder: (context, controller) => ListView(
      controller: controller,
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'privacyPolicyTitle'.tr(),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 16),
        Text(
          'privacyPolicyBody'.tr(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.6),
        ),
        if (AppConfig.privacyPolicyUrl.isNotEmpty)
          TextButton(
            onPressed: () => _openPolicy(context),
            child: Text('privacyPolicyFull'.tr()),
          ),
        if (AuthServiceScope.maybeOf(context)?.aiConsent != null)
          TextButton(
            onPressed: () {
              AuthServiceScope.maybeOf(context)?.aiConsent?.accepted = false;
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('aiConsentRevoked'.tr())));
            },
            child: Text('aiConsentRevoke'.tr()),
          ),
      ],
    ),
  ),
);

Future<void> _openPolicy(BuildContext context) async {
  final uri = Uri.tryParse(AppConfig.privacyPolicyUrl);
  try {
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Invalid policy URL');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('linkOpenError'.tr())));
    }
  }
}
