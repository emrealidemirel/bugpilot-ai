import 'dart:typed_data';

import 'package:bugpilot_ai/models/auth_user.dart';

abstract interface class AuthService {
  AuthUser? get currentUser;
  Stream<AuthUser?> get userChanges;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });
  Future<void> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  });
  Future<void> signInWithGoogle();
  Future<void> sendPasswordReset(String email);
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    Uint8List? photoBytes,
    String? photoContentType,
  });
  Future<void> signOut();
}
