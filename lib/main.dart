import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import 'app/account_app.dart';
import 'services/local_data_security.dart';
import 'services/account_data.dart';
import 'package:bugpilot_ai/services/firebase_auth_service.dart';
import 'package:bugpilot_ai/services/profile_photo_storage.dart';
import 'package:bugpilot_ai/constants/firebase_runtime_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  late Future<Widget> _app = _initialize();

  Future<Widget> _initialize() async {
    await Hive.initFlutter('bugpilot_ai');
    final key = await LocalDataSecurity.encryptionKey();
    final photoStorage = await ProfilePhotoStorage.create(encryptionKey: key);
    final pending = await LocalDataSecurity.pendingDeletion();
    if (pending != null) {
      final data = await AccountData.open(pending, key);
      await data.deleteAll();
      await photoStorage.delete(pending);
      await LocalDataSecurity.clearPendingDeletion();
      data.settings.dispose();
    }
    final options = FirebaseRuntimeConfig.options;
    if (options == null) throw StateError('Firebase is not configured');
    if (Firebase.apps.isEmpty) await Firebase.initializeApp(options: options);
    final auth = FirebaseAuthService(photoStorage: photoStorage);
    await LocalDataSecurity.bindLegacyOwner(auth.currentUser?.id);
    return AccountApp(auth: auth, encryptionKey: key);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Widget>(
    future: _app,
    builder: (context, snapshot) {
      if (snapshot.hasData) return snapshot.requireData;
      final tr =
          WidgetsBinding.instance.platformDispatcher.locale.languageCode ==
          'tr';
      return MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: Center(
              child: snapshot.hasError
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            tr
                                ? 'Uygulama başlatılamadı. Verileriniz silinmedi.'
                                : 'The app could not start. Your data has not been deleted.',
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(() => _app = _initialize()),
                            child: Text(tr ? 'Tekrar dene' : 'Retry'),
                          ),
                        ],
                      ),
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        ),
      );
    },
  );
}
