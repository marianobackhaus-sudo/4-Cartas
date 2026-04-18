import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_doc.dart';
import '../engine/models/game_state.dart';
import 'auth_providers.dart';
import 'providers.dart';

/// Real-time room doc stream, keyed by roomCode.
final roomStreamProvider =
    StreamProvider.family<RoomDoc?, String>((ref, code) {
  return ref.watch(roomRepositoryProvider).watch(code);
});

/// Convenience: the room's GameState, or null if not started.
final gameStateProvider = Provider.family<GameState?, String>((ref, code) {
  return ref.watch(roomStreamProvider(code)).asData?.value?.game;
});

/// True when the signed-in user owns the active turn.
final isMyTurnProvider = Provider.family<bool, String>((ref, code) {
  final game = ref.watch(gameStateProvider(code));
  final uid = ref.watch(currentUserIdProvider).asData?.value;
  if (game == null || uid == null) return false;
  return game.turnPlayerId == uid;
});
