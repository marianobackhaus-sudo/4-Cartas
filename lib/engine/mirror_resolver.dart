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
/// - Requires a valid top-of-discard card to match against.
/// - If the slot's card rank matches `lastDiscardRank` (or Joker vs Joker):
///     → ALL cards of that rank are removed (hand shrinks). Those cards go
///       to the top of discard (lastDiscard updates to the removed rank).
/// - If there is NO matching card in hand (penalty):
///     → hand stays untouched.
///     → `mirrorPenalty[uid]` is increased by 5 points.
/// - Special rule: if the top of discard is a Joker, only a Joker in hand
///   counts as a match.
/// - Allowed phases: turn, awaitingLastTurn. Not allowed during peekInitial,
///   reveal, roundEnd, gameEnd, matchEnd, or while a `pending` power is active.
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
  final topIsJoker = lastRank == null &&
      state.discard.isNotEmpty &&
      state.discard.last.isJoker;

  if (lastRank == null && !topIsJoker) {
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
  if (player.slots.isEmpty) {
    throw const GameError(
      GameErrorCode.invalidAction,
      'No cards to mirror',
    );
  }

  // Find ALL slots that match the top of discard.
  final List<int> matchingSlots;
  if (topIsJoker) {
    matchingSlots = [
      for (var i = 0; i < player.slots.length; i++)
        if (player.slots[i].card.isJoker) i,
    ];
  } else {
    matchingSlots = [
      for (var i = 0; i < player.slots.length; i++)
        if (!player.slots[i].card.isJoker && player.slots[i].card.rank == lastRank) i,
    ];
  }

  if (matchingSlots.isNotEmpty) {
    return _applyMirrorMatch(state, action.uid, matchingSlots);
  }
  return _applyMirrorMiss(state, action.uid);
}

// ── Match: ALL matching slots removed, cards → discard top ───────────────────

GameState _applyMirrorMatch(
  GameState state,
  String uid,
  List<int> matchSlots,
) {
  final player = state.player(uid);
  final removedCards = matchSlots.map((i) => player.slots[i].card).toList();

  // Remove slots in descending index order to preserve lower indices.
  final newSlots = List<HandSlot>.of(player.slots);
  for (final i in (matchSlots.toList()..sort((a, b) => b.compareTo(a)))) {
    newSlots.removeAt(i);
  }

  final newPlayers = Map<String, PlayerState>.of(state.players)
    ..[uid] = player.copyWith(slots: newSlots);

  final newDiscard = List<GameCard>.of(state.discard)..addAll(removedCards);
  final topRemoved = removedCards.last;

  return state.copyWith(
    players: newPlayers,
    discard: newDiscard,
    lastDiscardRank: topRemoved.isJoker ? null : topRemoved.rank,
    lastDiscardBy: uid,
  );
}

// ── Miss: +5 points penalty (hand untouched) ─────────────────────────────────

GameState _applyMirrorMiss(GameState state, String uid) {
  final penalty = Map<String, int>.of(state.mirrorPenalty);
  penalty[uid] = (penalty[uid] ?? 0) + 5;
  return state.copyWith(mirrorPenalty: penalty);
}
