import 'models/game_action.dart';
import 'models/game_error.dart';
import 'models/game_phase.dart';
import 'models/game_state.dart';
import 'models/hand_slot.dart';
import 'models/pending_action.dart';
import 'models/player_state.dart';
import 'rules.dart' show afterTurnEnd;

/// Resolves the current pending power using the ResolvePower action.
/// Mirrors the reducer contract: pure fn, throws GameError on invalid input.
///
/// Pending mapping:
/// - PendingPeekOwn (7, 8): peek is UI-only; action just clears pending and flips turn.
/// - PendingPeekOpponent (9, 10): same — clear pending, flip turn.
/// - PendingSwap (J, Q): requires ownSlot + opponentSlot → swap them.
/// - PendingKingPeek (K): two-phase.
///     * During peek phase (isComplete=false): action must include
///       peekOwnerUid + peekSlot. Adds to pending, stays in place.
///     * Decision phase (isComplete=true): action must set kingDecideSwap.
///       If true → also requires ownSlot + opponentSlot and does swap.
///       If false → cleared, turn flips.
GameState resolvePower(GameState state, ResolvePower action) {
  if (state.turnPlayerId != action.uid) {
    throw const GameError(
      GameErrorCode.notYourTurn,
      'Only the acting player resolves the power',
    );
  }
  if (state.phase != GamePhase.turn && state.phase != GamePhase.awaitingLastTurn) {
    throw GameError(
      GameErrorCode.wrongPhase,
      'Cannot resolve power in phase ${state.phase.name}',
    );
  }

  final pending = state.pending;
  if (pending == null) {
    throw const GameError(
      GameErrorCode.invalidAction,
      'No pending power to resolve',
    );
  }

  switch (pending) {
    case PendingPeekOwn():
    case PendingPeekOpponent():
      return afterTurnEnd(state.copyWith(pending: null));

    case PendingSwap():
      return _applyPowerSwap(state, action);

    case PendingKingPeek():
      return _applyKing(state, action, pending);
  }
}

// ── PendingSwap (J, Q) ───────────────────────────────────────────────────────

GameState _applyPowerSwap(GameState state, ResolvePower action) {
  final ownSlot = action.ownSlot;
  final opponentSlot = action.opponentSlot;
  if (ownSlot == null || opponentSlot == null) {
    throw const GameError(
      GameErrorCode.invalidTarget,
      'Swap requires ownSlot and opponentSlot',
    );
  }
  return afterTurnEnd(
    _swapBetweenPlayers(state, action.uid, ownSlot, opponentSlot)
        .copyWith(pending: null),
  );
}

// ── PendingKingPeek (K) ──────────────────────────────────────────────────────

GameState _applyKing(
  GameState state,
  ResolvePower action,
  PendingKingPeek pending,
) {
  // Phase 1 — still peeking (fewer than 2 peeks recorded).
  if (!pending.isComplete) {
    final peekOwner = action.peekOwnerUid;
    final peekSlot = action.peekSlot;
    if (peekOwner == null || peekSlot == null) {
      throw const GameError(
        GameErrorCode.invalidTarget,
        'King peek step requires peekOwnerUid and peekSlot',
      );
    }
    if (!state.players.containsKey(peekOwner)) {
      throw const GameError(
        GameErrorCode.invalidTarget,
        'Unknown peekOwnerUid',
      );
    }
    final ownerSlots = state.player(peekOwner).slots;
    if (peekSlot < 0 || peekSlot >= ownerSlots.length) {
      throw const GameError(
        GameErrorCode.invalidSlot,
        'peekSlot out of range',
      );
    }
    return state.copyWith(pending: pending.addPeek(peekOwner, peekSlot));
  }

  // Phase 2 — decide swap.
  final decide = action.kingDecideSwap;
  if (decide == null) {
    throw const GameError(
      GameErrorCode.invalidAction,
      'King decision requires kingDecideSwap',
    );
  }
  if (decide == false) {
    return afterTurnEnd(state.copyWith(pending: null));
  }
  // decide == true → swap using ownSlot + opponentSlot.
  final ownSlot = action.ownSlot;
  final opponentSlot = action.opponentSlot;
  if (ownSlot == null || opponentSlot == null) {
    throw const GameError(
      GameErrorCode.invalidTarget,
      'King swap requires ownSlot and opponentSlot',
    );
  }
  return afterTurnEnd(
    _swapBetweenPlayers(state, action.uid, ownSlot, opponentSlot)
        .copyWith(pending: null),
  );
}

// ── Shared: swap between players ─────────────────────────────────────────────

GameState _swapBetweenPlayers(
  GameState state,
  String uid,
  int ownSlotIndex,
  int opponentSlotIndex,
) {
  final opponentUid = state.opponentOf(uid);
  final me = state.player(uid);
  final opp = state.player(opponentUid);

  if (ownSlotIndex < 0 || ownSlotIndex >= me.slots.length) {
    throw const GameError(GameErrorCode.invalidSlot, 'ownSlot out of range');
  }
  if (opponentSlotIndex < 0 || opponentSlotIndex >= opp.slots.length) {
    throw const GameError(
      GameErrorCode.invalidSlot,
      'opponentSlot out of range',
    );
  }

  final mine = me.slots[ownSlotIndex];
  final theirs = opp.slots[opponentSlotIndex];

  // Post-swap: each slot holds the other's card. Knowledge is reset — neither
  // owner knows the new contents unless they peeked right before.
  final newMySlots = List<HandSlot>.of(me.slots);
  newMySlots[ownSlotIndex] = HandSlot(
    card: theirs.card,
    faceDown: true,
  );
  final newOppSlots = List<HandSlot>.of(opp.slots);
  newOppSlots[opponentSlotIndex] = HandSlot(
    card: mine.card,
    faceDown: true,
  );

  final newPlayers = Map<String, PlayerState>.of(state.players)
    ..[uid] = me.copyWith(slots: newMySlots)
    ..[opponentUid] = opp.copyWith(slots: newOppSlots);

  return state.copyWith(players: newPlayers);
}
