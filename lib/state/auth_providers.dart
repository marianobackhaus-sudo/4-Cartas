import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Streams full User object — fires on sign-in, sign-out, and profile updates.
final currentUserProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseAuthProvider).userChanges();
});

final currentUserIdProvider = FutureProvider<String>((ref) {
  return ref.watch(authRepositoryProvider).ensureSignedIn();
});
