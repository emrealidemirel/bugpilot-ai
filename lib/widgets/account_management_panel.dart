import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:bugpilot_ai/services/account_security_service.dart';
import 'auth_service_scope.dart';
import 'privacy_controls.dart';

class AccountManagementPanel extends StatefulWidget {
  const AccountManagementPanel({super.key});
  @override
  State<AccountManagementPanel> createState() => _AccountManagementPanelState();
}

class _AccountManagementPanelState extends State<AccountManagementPanel> {
  bool _busy = false;
  Future<bool>? _legacy;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _legacy ??= AuthServiceScope.maybeOf(
      context,
    )?.accountData?.hasLegacyReports();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AuthServiceScope.maybeOf(context);
    final service = scope?.service;
    final security = service is AccountSecurityService
        ? service as AccountSecurityService
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('privacyPolicyTitle'.tr()),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _busy ? null : () => showPrivacyInformation(context),
        ),
        if (security != null) ...[
          if (scope?.user?.emailVerified == false) ...[
            Text(
              'verifyEmailBeforeAi'.tr(),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Wrap(
              children: [
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(
                          security.sendVerificationEmail,
                          'verificationEmailSent',
                        ),
                  child: Text('sendVerificationEmail'.tr()),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => _run(security.refreshUser, 'accountRefreshed'),
                  child: Text('refreshAccount'.tr()),
                ),
              ],
            ),
          ],
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'deleteAccountAction'.tr(),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: _busy ? null : () => _deleteAccount(security),
          ),
        ],
        if (_legacy != null)
          FutureBuilder<bool>(
            future: _legacy,
            builder: (context, snapshot) => snapshot.data == true
                ? ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('importLegacyReports'.tr()),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _busy ? null : _importLegacy,
                  )
                : const SizedBox.shrink(),
          ),
        if (_busy) const LinearProgressIndicator(),
      ],
    );
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success.tr())));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('accountOperationFailed'.tr())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAccount(AccountSecurityService service) async {
    final password = await showDialog<String>(
      context: context,
      builder: (_) =>
          _DeleteAccountDialog(needsPassword: service.passwordAccount),
    );
    if (password == null || !mounted) return;
    await _run(
      () => service.deleteAccount(password: password),
      'accountDeleted',
    );
  }

  Future<void> _importLegacy() async {
    final data = AuthServiceScope.maybeOf(context)?.accountData;
    if (data == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('importLegacyReports'.tr()),
        content: Text('importLegacyDescription'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancelAction'.tr()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('importAction'.tr()),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    await _run(() async {
      await data.importLegacyReports();
      if (mounted) AuthServiceScope.maybeOf(context)?.onDataChanged?.call();
    }, 'legacyImported');
    if (mounted) setState(() => _legacy = data.hasLegacyReports());
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog({required this.needsPassword});
  final bool needsPassword;
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _password = TextEditingController();
  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('deleteAccountTitle'.tr()),
    content: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('deleteAccountDescription'.tr()),
          if (widget.needsPassword) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(labelText: 'passwordLabel'.tr()),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('cancelAction'.tr()),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _password.text),
        style: FilledButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
        child: Text('deleteAccountAction'.tr()),
      ),
    ],
  );
}

Future<void> showAccountManagementSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.48,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          children: [
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.manage_accounts_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'accountAndData'.tr(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            const AccountManagementPanel(),
          ],
        ),
      ),
    );
