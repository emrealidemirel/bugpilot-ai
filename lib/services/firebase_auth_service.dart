import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:bugpilot_ai/models/auth_user.dart';
import 'package:bugpilot_ai/services/auth_service.dart';
import 'package:bugpilot_ai/services/profile_photo_storage.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required this.photoStorage,
    firebase.FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? firebase.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final ProfilePhotoStorage photoStorage;
  final firebase.FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _googleInitialized = false;

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Stream<AuthUser?> get userChanges => Stream<AuthUser?>.multi((controller) {
    final authSubscription = _auth.userChanges().listen(
      (user) => controller.add(_mapUser(user)),
      onError: controller.addError,
    );
    final photoSubscription = photoStorage.changes.listen((userId) {
      final user = _auth.currentUser;
      if (user != null && user.uid == userId) {
        controller.add(_mapUser(user));
      }
    }, onError: controller.addError);
    controller.onCancel = () async {
      await authSubscription.cancel();
      await photoSubscription.cancel();
    };
  }, isBroadcast: true);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> createAccount({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(
      '${firstName.trim()} ${lastName.trim()}'.trim(),
    );
  }

  @override
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      final provider = firebase.GoogleAuthProvider();
      await _auth.signInWithPopup(provider);
      return;
    }

    if (!_googleInitialized) {
      // Native client IDs are read from GoogleService-Info.plist on iOS and
      // google-services.json on Android.
      await _googleSignIn.initialize();
      _googleInitialized = true;
    }
    final account = await _googleSignIn.authenticate();
    final credential = firebase.GoogleAuthProvider.credential(
      idToken: account.authentication.idToken,
    );
    await _auth.signInWithCredential(credential);
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    Uint8List? photoBytes,
    String? photoContentType,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('A signed-in user is required to update the profile.');
    }

    final displayName = '${firstName.trim()} ${lastName.trim()}'.trim();
    if (user.displayName != displayName) {
      await user.updateDisplayName(displayName);
    }
    if (photoBytes != null) {
      await photoStorage.save(user.uid, photoBytes);
    }
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    if (!kIsWeb && _googleInitialized) {
      await _googleSignIn.signOut();
    }
  }

  AuthUser? _mapUser(firebase.User? user) => user == null
      ? null
      : AuthUser(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          localPhotoBytes: photoStorage.read(user.uid),
        );
}
