import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bugpilot_ai/services/account_data.dart';
import 'package:bugpilot_ai/services/firebase_auth_service.dart';
import 'app.dart';

/// Recreates navigation and drafts at every identity boundary. A previous
/// account's asynchronous results cannot be rendered inside the new session.
class AccountApp extends StatefulWidget {
  const AccountApp({
    required this.auth,
    required this.encryptionKey,
    super.key,
  });
  final FirebaseAuthService auth;
  final List<int> encryptionKey;
  @override
  State<AccountApp> createState() => _AccountAppState();
}

class _AccountAppState extends State<AccountApp> {
  final _accounts = <String, Future<AccountData>>{};
  late final Stream<String?> _identities;
  @override
  void initState() {
    super.initState();
    _identities = widget.auth.userChanges.map((user) => user?.id).distinct();
    widget.auth.deleteLocalData = (uid) async {
      final data = await _data(uid);
      await data.deleteAll();
    };
  }

  @override
  void dispose() {
    widget.auth.deleteLocalData = null;
    for (final future in _accounts.values) {
      unawaited(
        future.then<void>(
          (data) => data.settings.dispose(),
          onError: (Object _) {},
        ),
      );
    }
    super.dispose();
  }

  Future<AccountData> _data(String uid) => _accounts.putIfAbsent(
    uid,
    () => AccountData.open(uid, widget.encryptionKey),
  );

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: _identities,
    initialData: widget.auth.currentUser?.id,
    builder: (context, identity) {
      final uid = identity.data;
      if (uid == null) {
        return BugPilotApp(
          key: const ValueKey('signed-out'),
          authService: widget.auth,
          requireAuthentication: true,
        );
      }
      return FutureBuilder<AccountData>(
        key: ValueKey(uid),
        future: _data(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const MaterialApp(
              home: Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
          if (snapshot.hasError) {
            final tr =
                WidgetsBinding
                    .instance
                    .platformDispatcher
                    .locale
                    .languageCode ==
                'tr';
            return MaterialApp(
              home: Scaffold(
                body: SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr
                                ? 'Hesap verileri açılamadı. Verileriniz silinmedi.'
                                : 'Account data could not be opened. Your data has not been deleted.',
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _accounts.remove(uid)),
                            child: Text(tr ? 'Tekrar dene' : 'Retry'),
                          ),
                          TextButton(
                            onPressed: widget.auth.signOut,
                            child: Text(tr ? 'Oturumu kapat' : 'Sign out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
          final data = snapshot.requireData;
          return BugPilotApp(
            key: ValueKey('account-$uid'),
            bugRepository: data.reports,
            settingsController: data.settings,
            accountData: data,
            authService: widget.auth,
            requireAuthentication: true,
          );
        },
      );
    },
  );
}
