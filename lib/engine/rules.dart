import '../core/constants.dart';
import 'models/card.dart';
import 'models/game_action.dart';
import 'models/game_error.dart';
import 'models/game_phase.dart';
import 'models/game_state.dart';
import 'models/hand_slot.dart';
import 'models/pending_action.dart';
import 'models/player_state.dart';
import 'mirror_resolver.dart';
import 'power_resolver.dart';
import 'scoring.dart';

/// Pure reducer: (state, action) -> state. Throws GameError on invalid input.
/// No Flutter/Firebase imports — fully testable.
GameState apply(GameState state, GameAction action) {
  switch (action) {
    case CompleteInitialPeek():
      return _applyCompleteInitialPeek(state, action);
    case DrawFromDeck():
      return _applyDrawFromDeck(state, action);
    case SwapDrawnWithSlot():
      return _applySwap(state, action);
    case DiscardDrawn():
      return _applyDiscard(state, action);
    case ResolvePower():
      return resolvePower(state, action);
    case Cut():
      return _applyCut(state, action);
    case MirrorAttempt():
      return resolveMirror(state, action);
  }
}

// ── Transitions ──────────────────────────────────────────────────────────────

GameState _applyCompleteInitialPeek(
  GameState state,
  CompleteInitialPeek action,
) {
  if (state.phase != GamePhase.peekInitial) {
    throw const GameError(
      GameErrorCode.wrongPhase,
      'Initial peek only allowed in peekInitial phase',
    );
  }
  if (!state.players.containsKey(action.uid)) {
    throw const GameError(
      GameErrorCode.invalidAction,
      'Unknown player',
    );
  }
  if (state.initialPeeksDone[action.uid] == true) {
    throw const GameError(
      GameErrorCode.alreadyPeeked,
      'Player already completed initial peek',
    );
  }

  final updatedPeeks = {
    ...state.initialPeeksDone,
    action.uid: true,
  };
  final bothDone = state.seatOrder.every((u) => updatedPeeks[u] == true);

  return state.copyWith(
    initialPeeksDone: updatedPeeks,
    phase: bothDone ? GamePhase.turn : GamePhase.peekInitial,
  );
}

GameState _applyDrawFromDeck(GameState state, DrawFromDeck action) {
  _requireTurn(state, action.uid);
  _requirePhase(state, const {GamePhase.turn, GamePhase.awaitingLastTurn});
  _requireNoPending(state);
  if (state.drawnCard != null) {
    throw const GameError(
      GameErrorCode.alreadyDrawn,
      'There is already a drawn card — resolve it first',
    );
  }
  if (state.deck.isEmpty) {
    throw const GameError(GameErrorCode.deckEmpty, 'Deck is empty');
  }

  final top = state.deck.last;
  final newDeck = List<GameCard>.of(state.deck)..removeLast();

  return state.copyWith(deck: newDeck, drawnCard: top);
}

GameState _applySwap(GameState state, SwapDrawnWithSlot action) {
  _requireTurn(state, action.uid);
  _requirePhase(state, const {GamePhase.turn, GamePhase.awaitingLastTurn});
  _requireNoPending(state);
  final drawn = state.drawnCard;
  if (drawn == null) {
    throw const GameError(
      GameErrorCode.noDrawnCard,
      'No drawn card to swap',
    );
  }
  final player = state.player(action.uid);
  if (action.slotIndex < 0 || action.slotIndex >= player.slots.length) {
    throw const GameError(
      GameErrorCode.invalidSlot,
      'Slot index out of range',
    );
  }

  final oldSlot = player.slots[action.slotIndex];
  final newSlots = List<HandSlot>.of(player.slots);
  // Swapped card becomes known to the owner but stored face-down on the table.
  newSlots[action.slotIndex] = HandSlot(
    card: drawn,
    faceDown: true,
    knownToOwner: true,
  );

  final updatedPlayer = player.copyWith(slots: newSlots);
  final newPlayers = Map<String, PlayerState>.of(state.players)
    ..[action.uid] = updatedPlayer;

  final newDiscard = List<GameCard>.of(state.discard)..add(oldSlot.card);

  return afterTurnEnd(
    state.copyWith(
      players: newPlayers,
      discard: newDiscard,
      drawnCard: null,
      lastDiscardRank: oldSlot.card.isJoker ? null : oldSlot.card.rank,
      lastDiscardBy: action.uid,
    ),
  );
}

GameState _applyCut(GameState state, Cut action) {
  _requireTurn(state, action.uid);
  _requirePhase(state, const {GamePhase.turn});
  _requireNoPending(state);
  if (state.cutterId != null) {
    throw const GameError(
      GameErrorCode.cannotCutNow,
      'Round already has a cutter',
    );
  }
  if (state.cutPending) {
    throw const GameError(
      GameErrorCode.cannotCutNow,
      'Cut already pending',
    );
  }
  // If holding a drawn card, defer the cut until the card is resolved.
  if (state.drawnCard != null) {
    return state.copyWith(cutPending: true);
  }
  // Normal cut: no drawn card → enter awaitingLastTurn immediately.
  return _flipTurn(
    state.copyWith(
      cutterId: action.uid,
      phase: GamePhase.awaitingLastTurn,
    ),
  );
}

GameState _applyDiscard(GameState state, DiscardDrawn action) {
  _requireTurn(state, action.uid);
  _requirePhase(state, const {GamePhase.turn, GamePhase.awaitingLastTurn});
  _requireNoPending(state);
  final drawn = state.drawnCard;
  if (drawn == null) {
    throw const GameError(
      GameErrorCode.noDrawnCard,
      'No drawn card to discard',
    );
  }

  final newDiscard = List<GameCard>.of(state.discard)..add(drawn);
  final pending = _pendingForDiscard(drawn);

  final next = state.copyWith(
    discard: newDiscard,
    drawnCard: null,
    pending: pending,
    lastDiscardRank: drawn.isJoker ? null : drawn.rank,
    lastDiscardBy: action.uid,
  );

  // If no power triggered, turn ends. If power pending, turn stays until resolved.
  return pending == null ? afterTurnEnd(next) : next;
}

// ── Initial setup ────────────────────────────────────────────────────────────

/// Sets up the first round of a game:
/// - Deals `handSize` (4) face-down slots to each seat.
/// - Flips the next card to the discard pile to determine `firstFlippedRank`.
/// - `totalRounds = clamp(firstFlippedRank, 1, 5)`. Joker → 1.
/// - Phase = peekInitial. Turn = seatOrder[0].
///
/// `shuffledDeck` must come pre-shuffled by the host (host-authoritative shuffle).
GameState setupInitialState({
  required List<String> seatOrder,
  required List<GameCard> shuffledDeck,
  int gameIndex = 0,
  Map<String, int>? gamesWon,
}) {
  if (seatOrder.length != 2) {
    throw ArgumentError('Exactly 2 seats required for MVP');
  }
  final needed = seatOrder.length * GameConfig.handSize + 1;
  if (shuffledDeck.length < needed) {
    throw ArgumentError('Deck too small — need $needed cards');
  }

  final deck = List<GameCard>.of(shuffledDeck);
  final players = <String, PlayerState>{};

  // Deal face-down; none known to owner yet (initial peek picks 2 later).
  for (final uid in seatOrder) {
    final slots = <HandSlot>[];
    for (var i = 0; i < GameConfig.handSize; i++) {
      slots.add(HandSlot(card: deck.removeLast(), faceDown: true));
    }
    players[uid] = PlayerState(uid: uid, slots: slots);
  }

  // Flip starter card — determines round count.
  final starter = deck.removeLast();
  final firstRank = starter.isJoker ? 1 : starter.rank;
  final totalRounds = firstRank.clamp(
    GameConfig.minRounds,
    GameConfig.maxRounds,
  );

  final zeros = {for (final uid in seatOrder) uid: 0};
  final peeks = {for (final uid in seatOrder) uid: false};

  return GameState(
    deck: deck,
    discard: [starter],
    players: players,
    seatOrder: seatOrder,
    phase: GamePhase.peekInitial,
    turnPlayerId: seatOrder[0],
    initialPeeksDone: peeks,
    firstFlippedRank: firstRank,
    totalRounds: totalRounds,
    roundIndex: 0,
    roundPoints: zeros,
    gameIndex: gameIndex,
    gamesWon: gamesWon ?? zeros,
    lastDiscardRank: starter.isJoker ? null : starter.rank,
    lastDiscardBy: null,
    mirrorPenalty: zeros,
  );
}

// ── Round / game / match flow ────────────────────────────────────────────────

/// Consumes the `reveal` phase: accumulates roundPoints, determines round
/// winner, detects golden round, and advances phase to one of:
/// `roundEnd` (play another round), `gameEnd` (game decided), or `matchEnd`
/// (2 gamesWon reached).
///
/// Called by the controller after the reveal animation finishes. The caller
/// is responsible for providing a fresh shuffled deck via `startNextRound`
/// or `startNextGame` when the player acknowledges.
GameState advanceFromReveal(GameState state) {
  if (state.phase != GamePhase.reveal) {
    throw GameError(
      GameErrorCode.wrongPhase,
      'advanceFromReveal called in phase ${state.phase.name}',
    );
  }

  final winner = resolveRoundOutcome(state);

  // Golden round (tie): do NOT accumulate, do NOT advance roundIndex — replay.
  if (winner == null) {
    return state.copyWith(
      phase: GamePhase.roundEnd,
      goldenRound: true,
      roundWinnerUid: null,
    );
  }

  // Clear winner: both players' hand scores go into roundPoints.
  final a = state.seatOrder[0];
  final b = state.seatOrder[1];
  final newPoints = Map<String, int>.of(state.roundPoints);
  newPoints[a] = (newPoints[a] ?? 0) + scoreHandWithPenalty(state, a);
  newPoints[b] = (newPoints[b] ?? 0) + scoreHandWithPenalty(state, b);

  final nextRoundIdx = state.roundIndex + 1;
  final gameComplete = nextRoundIdx >= state.totalRounds;

  if (!gameComplete) {
    return state.copyWith(
      phase: GamePhase.roundEnd,
      roundPoints: newPoints,
      roundWinnerUid: winner,
      roundIndex: nextRoundIdx,
      goldenRound: false,
    );
  }

  // Game over — lowest accumulated roundPoints wins the game.
  final pointsA = newPoints[a]!;
  final pointsB = newPoints[b]!;
  String? gameWinner;
  if (pointsA < pointsB) {
    gameWinner = a;
  } else if (pointsB < pointsA) {
    gameWinner = b;
  }
  // Tie → neither increments gamesWon; controller should startNextGame anyway.

  final newGamesWon = Map<String, int>.of(state.gamesWon);
  if (gameWinner != null) {
    newGamesWon[gameWinner] = (newGamesWon[gameWinner] ?? 0) + 1;
  }

  String? matchWinner;
  for (final uid in state.seatOrder) {
    if ((newGamesWon[uid] ?? 0) >= GameConfig.gamesToWinMatch) {
      matchWinner = uid;
      break;
    }
  }

  return state.copyWith(
    phase: matchWinner != null ? GamePhase.matchEnd : GamePhase.gameEnd,
    roundPoints: newPoints,
    roundWinnerUid: winner,
    roundIndex: nextRoundIdx,
    gamesWon: newGamesWon,
    matchWinnerUid: matchWinner,
    goldenRound: false,
  );
}

/// Starts the next round within the current game. `totalRounds` and
/// accumulated `roundPoints` / `gamesWon` are preserved. Fresh shuffled deck
/// must be supplied by the caller (host reshuffles every round for MVP).
///
/// On a golden round this is also the call used to replay the tied round.
GameState startNextRound({
  required GameState state,
  required List<GameCard> shuffledDeck,
}) {
  if (state.phase != GamePhase.roundEnd) {
    throw GameError(
      GameErrorCode.wrongPhase,
      'startNextRound called in phase ${state.phase.name}',
    );
  }
  final needed = state.seatOrder.length * GameConfig.handSize;
  if (shuffledDeck.length < needed) {
    throw ArgumentError('Deck too small — need $needed cards');
  }

  final deck = List<GameCard>.of(shuffledDeck);
  final players = <String, PlayerState>{};
  for (final uid in state.seatOrder) {
    final slots = <HandSlot>[];
    for (var i = 0; i < GameConfig.handSize; i++) {
      slots.add(HandSlot(card: deck.removeLast(), faceDown: true));
    }
    players[uid] = PlayerState(uid: uid, slots: slots);
  }

  final peeks = {for (final uid in state.seatOrder) uid: false};

  return state.copyWith(
    deck: deck,
    discard: const [],
    players: players,
    phase: GamePhase.peekInitial,
    turnPlayerId: state.seatOrder[0],
    drawnCard: null,
    pending: null,
    initialPeeksDone: peeks,
    cutterId: null,
    goldenRound: false,
    roundWinnerUid: null,
    lastDiscardRank: null,
    lastDiscardBy: null,
    mirrorPenalty: {for (final uid in state.seatOrder) uid: 0},
    cutPending: false,
  );
}

/// Starts a new game within the same match. Resets per-game state but keeps
/// `gamesWon` and `seatOrder`. Flips a new starter card → recalculates
/// `totalRounds` and `firstFlippedRank`.
GameState startNextGame({
  required GameState state,
  required List<GameCard> shuffledDeck,
}) {
  if (state.phase != GamePhase.gameEnd) {
    throw GameError(
      GameErrorCode.wrongPhase,
      'startNextGame called in phase ${state.phase.name}',
    );
  }
  final needed = state.seatOrder.length * GameConfig.handSize + 1;
  if (shuffledDeck.length < needed) {
    throw ArgumentError('Deck too small — need $needed cards');
  }

  final deck = List<GameCard>.of(shuffledDeck);
  final players = <String, PlayerState>{};
  for (final uid in state.seatOrder) {
    final slots = <HandSlot>[];
    for (var i = 0; i < GameConfig.handSize; i++) {
      slots.add(HandSlot(card: deck.removeLast(), faceDown: true));
    }
    players[uid] = PlayerState(uid: uid, slots: slots);
  }

  final starter = deck.removeLast();
  final firstRank = starter.isJoker ? 1 : starter.rank;
  final totalRounds = firstRank.clamp(
    GameConfig.minRounds,
    GameConfig.maxRounds,
  );

  final zeros = {for (final uid in state.seatOrder) uid: 0};
  final peeks = {for (final uid in state.seatOrder) uid: false};

  return state.copyWith(
    deck: deck,
    discard: [starter],
    players: players,
    phase: GamePhase.peekInitial,
    turnPlayerId: state.seatOrder[0],
    drawnCard: null,
    pending: null,
    initialPeeksDone: peeks,
    cutterId: null,
    goldenRound: false,
    roundWinnerUid: null,
    firstFlippedRank: firstRank,
    totalRounds: totalRounds,
    roundIndex: 0,
    roundPoints: zeros,
    gameIndex: state.gameIndex + 1,
    lastDiscardRank: starter.isJoker ? null : starter.rank,
    lastDiscardBy: null,
    mirrorPenalty: zeros,
    cutPending: false,
  );
}

// ── Helpers ──────────────────────────────────────────────────────────────────

void _requireTurn(GameState state, String uid) {
  if (state.turnPlayerId != uid) {
    throw const GameError(
      GameErrorCode.notYourTurn,
      'Action requires active turn',
    );
  }
}

void _requirePhase(GameState state, Set<GamePhase> allowed) {
  if (!allowed.contains(state.phase)) {
    throw GameError(
      GameErrorCode.wrongPhase,
      'Action not allowed in phase ${state.phase.name}',
    );
  }
}

void _requireNoPending(GameState state) {
  if (state.pending != null) {
    throw const GameError(
      GameErrorCode.pendingNotResolved,
      'Resolve pending power first',
    );
  }
}

/// Returns a PendingAction if the given discarded card triggers a power.
/// Null otherwise. Jokers never trigger powers.
PendingAction? _pendingForDiscard(GameCard card) {
  if (card.isJoker) return null;
  switch (card.rank) {
    case 7:
    case 8:
      return PendingPeekOwn(rank: card.rank);
    case 9:
    case 10:
      return PendingPeekOpponent(rank: card.rank);
    case 11:
    case 12:
      return PendingSwap(rank: card.rank);
    case 13:
      return const PendingKingPeek();
    default:
      return null;
  }
}

/// Flips the turn and transitions awaitingLastTurn → reveal when the last
/// turn after a Cut completes.
GameState afterTurnEnd(GameState state) {
  if (state.phase == GamePhase.awaitingLastTurn &&
      state.cutterId != null &&
      state.turnPlayerId != state.cutterId) {
    // The non-cutter just finished their last turn — enter reveal phase.
    return state.copyWith(phase: GamePhase.reveal);
  }
  // Fire a deferred cut now that the drawn card has been resolved.
  if (state.cutPending) {
    return _flipTurn(
      state.copyWith(
        cutPending: false,
        cutterId: state.turnPlayerId,
        phase: GamePhase.awaitingLastTurn,
      ),
    );
  }
  return _flipTurn(state);
}

GameState _flipTurn(GameState state) {
  final other = state.opponentOf(state.turnPlayerId);
  return state.copyWith(turnPlayerId: other);
}
