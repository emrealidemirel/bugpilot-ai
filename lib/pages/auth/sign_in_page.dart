import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:bugpilot_ai/services/account_security_service.dart';
import 'package:bugpilot_ai/widgets/privacy_controls.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'package:bugpilot_ai/widgets/bugpilot_components.dart';

import 'package:bugpilot_ai/utils/localization_extensions.dart';
import 'package:bugpilot_ai/services/auth_service.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({this.authService, super.key});

  static const routePath = '/sign-in';
  final AuthService? authService;

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _createAccount = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ready = widget.authService != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -12),
                      child: const Center(child: BugPilotLogoMark(size: 52)),
                    ),
                    const SizedBox(height: 24),
                    if (!ready) ...[
                      Text(
                        l10n.firebaseSetupRequired,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (_createAccount) ...[
                      TextFormField(
                        controller: _firstNameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.givenName],
                        decoration: InputDecoration(
                          labelText: 'firstNameLabel'.tr(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'profileNameRequired'.tr()
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _lastNameController,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.familyName],
                        decoration: InputDecoration(
                          labelText: 'lastNameLabel'.tr(),
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'profileNameRequired'.tr()
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: InputDecoration(labelText: l10n.emailLabel),
                      validator: (value) =>
                          value == null || !value.contains('@')
                          ? l10n.validEmailMessage
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: l10n.passwordLabel,
                      ),
                      validator: (value) => value == null || value.length < 6
                          ? l10n.passwordMinMessage
                          : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: ready && !_busy ? _submit : null,
                      child: Text(
                        _busy
                            ? l10n.pleaseWait
                            : _createAccount
                            ? l10n.createAccount
                            : l10n.signIn,
                      ),
                    ),
                    TextButton(
                      onPressed: ready && !_busy
                          ? () =>
                                setState(() => _createAccount = !_createAccount)
                          : null,
                      child: Text(
                        _createAccount
                            ? l10n.haveAccountSignIn
                            : l10n.needAccountCreate,
                      ),
                    ),
                    TextButton(
                      onPressed: ready && !_busy ? _resetPassword : null,
                      child: Text(l10n.forgotPassword),
                    ),
                    TextButton(
                      onPressed: () => showPrivacyInformation(context),
                      child: Text('privacyPolicyTitle'.tr()),
                    ),
                    const Divider(height: 28),
                    OutlinedButton.icon(
                      onPressed: ready && !_busy ? _googleSignIn : null,
                      icon: const Icon(Icons.account_circle_outlined),
                      label: Text(l10n.continueWithGoogle),
                    ),
                    if (widget.authService
                        case final AccountSecurityService security
                        when security.supportsAppleSignIn)
                      OutlinedButton.icon(
                        onPressed: _busy
                            ? null
                            : () => _run(security.signInWithApple),
                        icon: const Icon(Icons.apple),
                        label: Text('continueWithApple'.tr()),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _run(() async {
      if (_createAccount) {
        await widget.authService!.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
        );
      } else {
        await widget.authService!.signInWithEmail(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    });
  }

  Future<void> _googleSignIn() => _run(widget.authService!.signInWithGoogle);

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = context.l10n.validEmailMessage);
      return;
    }
    await _run(() => widget.authService!.sendPasswordReset(email));
    if (mounted && _error == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.passwordResetSent)));
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on firebase.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = switch (error.code) {
          'email-already-in-use' => context.l10n.emailAlreadyInUse,
          'invalid-credential' ||
          'wrong-password' ||
          'user-not-found' => context.l10n.invalidCredentials,
          'invalid-email' => context.l10n.validEmailMessage,
          'too-many-requests' => 'authTooManyRequests'.tr(),
          'user-disabled' => 'authUserDisabled'.tr(),
          'operation-not-allowed' => 'authProviderDisabled'.tr(),
          'keychain-error' => 'authKeychainError'.tr(),
          'weak-password' => context.l10n.passwordMinMessage,
          'network-request-failed' => context.l10n.networkError,
          _ => 'authErrorWithCode'.tr(namedArgs: {'code': error.code}),
        },
      );
    } on GoogleSignInException catch (error) {
      if (!mounted || error.code == GoogleSignInExceptionCode.canceled) return;
      setState(() {
        _error = switch (error.code) {
          GoogleSignInExceptionCode.clientConfigurationError ||
          GoogleSignInExceptionCode.providerConfigurationError =>
            'authGoogleConfigurationError'.tr(),
          _ => 'authErrorWithCode'.tr(namedArgs: {'code': error.code.name}),
        };
      });
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () =>
              _error = 'authErrorWithCode'.tr(namedArgs: {'code': error.code}),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.authGenericError);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
