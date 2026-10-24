/// Account verification and destructive account operations.
abstract interface class AccountSecurityService {
  bool get supportsAppleSignIn;
  bool get passwordAccount;
  Future<void> signInWithApple();
  Future<void> sendVerificationEmail();
  Future<void> refreshUser();
  Future<void> deleteAccount({String? password});
}
