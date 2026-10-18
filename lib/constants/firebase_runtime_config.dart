import 'package:firebase_core/firebase_core.dart';

import 'package:bugpilot_ai/firebase_options.dart';

class FirebaseRuntimeConfig {
  const FirebaseRuntimeConfig._();

  static FirebaseOptions? get options {
    try {
      return DefaultFirebaseOptions.currentPlatform;
    } on UnsupportedError {
      return null;
    }
  }

  static bool get isConfigured => options != null;
}
