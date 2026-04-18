import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper over FirebaseAuth — all we need for MVP is anonymous sign-in
/// and reading the current user's uid.
class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  /// Current signed-in uid, or null if not signed in.
  String? get currentUid => _auth.currentUser?.uid;

  /// Signs in anonymously if not already signed in. Returns the uid.
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;
    final cred = await _auth.signInAnonymously();
    final uid = cred.user?.uid;
    if (uid == null) {
      throw StateError('signInAnonymously returned null user');
    }
    return uid;
  }

}
