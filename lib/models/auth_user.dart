import 'dart:typed_data';

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.localPhotoBytes,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final Uint8List? localPhotoBytes;
}
