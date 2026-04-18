import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Ensures anonymous sign-in and exposes the current uid. Awaited on boot.
final currentUserIdProvider = FutureProvider<String>((ref) {
  return ref.watch(authRepositoryProvider).ensureSignedIn();
});
