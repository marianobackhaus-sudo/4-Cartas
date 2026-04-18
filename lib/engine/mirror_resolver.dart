import 'models/card.dart';
import 'models/game_action.dart';
import 'models/game_error.dart';
import 'models/game_phase.dart';
import 'models/game_state.dart';
import 'models/hand_slot.dart';
import 'models/player_state.dart';

/// Resolves a MirrorAttempt.
///
/// Rules:
/// - Any player can attempt a mirror at any time during active play,
///   regardless of whose turn it is. Does NOT change `turnPlayerId`.
/// - Requires `state.lastDiscardRank != null` (there's a top discard to match).
/// - If the slot's card rank matches `lastDiscardRank`:
///     → slot is removed (hand shrinks). Slot's card goes to the top of discard
///       (becoming the new lastDiscard).
/// - If it does NOT match (penalty):
///     → hand stays untouched (cards stay hidden).
///     → `mirrorPenalty[uid]` is increased by 5 points. Added to the
///       player's score at round reveal.
/// - Jokers cannot be mirrored (rank sentinel 0, never matches discard).
/// - Allowed phases: turn, awaitingLastTurn. Not allowed during peekInitial,
///   reveal, roundEnd, gameEnd, matchEnd, or while a `pending` power is active
///   (to avoid conflicting with the discarder's power resolution).
GameState resolveMirror(GameState state, MirrorAttempt action) {
  if (state.phase != GamePhase.turn && state.phase != GamePhase.awaitingLastTurn) {
    throw GameError(
      GameErrorCode.wrongPhase,
      'Mirror not allowed in phase ${state.phase.name}',
    );
  }
  if (state.pending != null) {
    throw const GameError(
      GameErrorCode.pendingNotResolved,
      'Mirror blocked while a power is pending',
    );
  }
  final lastRank = state.lastDiscardRank;
  if (lastRank == null) {
    throw const GameError(
      GameErrorCode.invalidAction,
      'No discard to mirror against',
    );
  }
  if (!state.players.containsKey(action.uid)) {
    throw const GameError(
      GameErrorCode.invalidAction,
      'Unknown player',
    );
  }

  final player = state.player(action.uid);
  if (action.slotIndex < 0 || action.slotIndex >= player.slots.length) {
    throw const GameError(
      GameErrorCode.invalidSlot,
      'slotIndex out of range',
    );
  }

  final slot = player.slots[action.slotIndex];
  final slotCard = slot.card;

  if (!slotCard.isJoker && slotCard.rank == lastRank) {
    return _applyMirrorMatch(state, action.uid, action.slotIndex, slotCard);
  }
  return _applyMirrorMiss(state, action.uid);
}

// ── Match: slot removed, card → discard top ──────────────────────────────────

GameState _applyMirrorMatch(
  GameState state,
  String uid,
  int slotIndex,
  GameCard removedCard,
) {
  final player = state.player(uid);
  final newSlots = List<HandSlot>.of(player.slots)..removeAt(slotIndex);
  final newPlayers = Map<String, PlayerState>.of(state.players)
    ..[uid] = player.copyWith(slots: newSlots);

  final newDiscard = List<GameCard>.of(state.discard)..add(removedCard);

  return state.copyWith(
    players: newPlayers,
    discard: newDiscard,
    lastDiscardRank: removedCard.isJoker ? null : removedCard.rank,
    lastDiscardBy: uid,
  );
}

// ── Miss: +5 points penalty (hand untouched) ─────────────────────────────────

GameState _applyMirrorMiss(GameState state, String uid) {
  final penalty = Map<String, int>.of(state.mirrorPenalty);
  penalty[uid] = (penalty[uid] ?? 0) + 5;
  return state.copyWith(mirrorPenalty: penalty);
}
