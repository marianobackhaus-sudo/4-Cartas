import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/room_repository.dart';
import '../engine/deck.dart';
import '../engine/models/game_action.dart';
import '../engine/rules.dart' as engine_rules;
import 'providers.dart';

/// Orchestrates game actions for a given room. All methods mutate the room
/// doc inside a Firestore transaction via [RoomRepository]; the engine
/// reducer is the single source of truth for validation.
class GameController {
  GameController(this._repo, this._roomCode);

  final RoomRepository _repo;
  final String _roomCode;

  // ── Lifecycle ───────────────────────────────────────────────────────────
  Future<void> startMatch() => _repo.startFirstGame(_roomCode);

  // ── Initial peek ────────────────────────────────────────────────────────
  Future<void> completeInitialPeek(String uid) =>
      _dispatch(CompleteInitialPeek(uid));

  // ── Turn actions ────────────────────────────────────────────────────────
  Future<void> drawFromDeck(String uid) => _dispatch(DrawFromDeck(uid));
  Future<void> swap(String uid, int slotIndex) =>
      _dispatch(SwapDrawnWithSlot(uid, slotIndex));
  Future<void> discardDrawn(String uid) => _dispatch(DiscardDrawn(uid));
  Future<void> cut(String uid) => _dispatch(Cut(uid));

  // ── Power resolution ────────────────────────────────────────────────────
  /// For 7/8 (peek-own) and 9/10 (peek-opponent) the effect is UI-only — the
  /// server-side reducer just clears pending and flips the turn.
  Future<void> acknowledgePeek(String uid) => _dispatch(ResolvePower(uid));

  /// J, Q or King (decision phase = swap): swap slots between players.
  Future<void> powerSwap(
    String uid, {
    required int ownSlot,
    required int opponentSlot,
  }) =>
      _dispatch(ResolvePower(uid, ownSlot: ownSlot, opponentSlot: opponentSlot));

  /// King peek step — adds one peeked slot to pending.
  Future<void> kingPeek(
    String uid, {
    required String peekOwnerUid,
    required int peekSlot,
  }) =>
      _dispatch(ResolvePower(uid,
          peekOwnerUid: peekOwnerUid, peekSlot: peekSlot));

  /// King decision with no swap.
  Future<void> kingDecline(String uid) =>
      _dispatch(ResolvePower(uid, kingDecideSwap: false));

  /// King decision with swap (equivalent to powerSwap but with kingDecideSwap=true).
  Future<void> kingSwap(
    String uid, {
    required int ownSlot,
    required int opponentSlot,
  }) =>
      _dispatch(ResolvePower(
        uid,
        kingDecideSwap: true,
        ownSlot: ownSlot,
        opponentSlot: opponentSlot,
      ));

  // ── Mirror ──────────────────────────────────────────────────────────────
  Future<void> mirrorAttempt(String uid, int slotIndex) =>
      _dispatch(MirrorAttempt(uid, slotIndex));

  // ── Round / game flow ───────────────────────────────────────────────────
  Future<void> advanceReveal() => _repo.updateGame(
        code: _roomCode,
        update: engine_rules.advanceFromReveal,
      );

  Future<void> nextRound() {
    final deck = shuffleDeck(buildDeck());
    return _repo.updateGame(
      code: _roomCode,
      update: (g) =>
          engine_rules.startNextRound(state: g, shuffledDeck: deck),
    );
  }

  Future<void> nextGame() {
    final deck = shuffleDeck(buildDeck());
    return _repo.updateGame(
      code: _roomCode,
      update: (g) =>
          engine_rules.startNextGame(state: g, shuffledDeck: deck),
    );
  }

  // ── Internal ────────────────────────────────────────────────────────────
  Future<void> _dispatch(GameAction action) {
    return _repo.updateGame(
      code: _roomCode,
      update: (g) => engine_rules.apply(g, action),
    );
  }
}

final gameControllerProvider = Provider.family<GameController, String>(
  (ref, code) => GameController(ref.watch(roomRepositoryProvider), code),
);
