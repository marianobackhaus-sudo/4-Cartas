import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._auth);
  final FirebaseAuth _auth;

  String? get currentUid => _auth.currentUser?.uid;

  Future<String> signInWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }

  Future<String> registerWithEmail(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user!.uid;
  }

  Future<void> updateDisplayName(String name) =>
      _auth.currentUser!.updateDisplayName(name);

  Future<void> signOut() => _auth.signOut();

  /// Legacy: ensures any signed-in session (used by game flow for uid reads).
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) return existing.uid;
    throw StateError('No authenticated user');
  }
}
