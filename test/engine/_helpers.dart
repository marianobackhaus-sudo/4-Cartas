import 'package:juego_cartas_4/engine/models/card.dart';
import 'package:juego_cartas_4/engine/models/game_phase.dart';
import 'package:juego_cartas_4/engine/models/game_state.dart';
import 'package:juego_cartas_4/engine/models/hand_slot.dart';
import 'package:juego_cartas_4/engine/models/pending_action.dart';
import 'package:juego_cartas_4/engine/models/player_state.dart';

/// Builds a synthetic GameState for unit tests — no shuffle randomness.
GameState makeState({
  List<GameCard>? deck,
  List<GameCard>? discard,
  Map<String, List<GameCard>>? hands,
  List<String> seatOrder = const ['A', 'B'],
  GamePhase phase = GamePhase.turn,
  String turnPlayerId = 'A',
  GameCard? drawnCard,
  PendingAction? pending,
  String? cutterId,
  int totalRounds = 5,
  int roundIndex = 0,
  Map<String, int>? roundPoints,
  Map<String, int>? gamesWon,
  int? lastDiscardRank,
  String? lastDiscardBy,
}) {
  final players = <String, PlayerState>{};
  final effectiveHands = hands ??
      {
        for (final uid in seatOrder)
          uid: [
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.clubs, 3),
            const GameCard.regular(Suit.diamonds, 4),
            const GameCard.regular(Suit.spades, 5),
          ],
      };
  for (final uid in seatOrder) {
    players[uid] = PlayerState(
      uid: uid,
      slots: effectiveHands[uid]!
          .map((c) => HandSlot(card: c, faceDown: true))
          .toList(),
    );
  }

  return GameState(
    deck: deck ?? const [GameCard.regular(Suit.hearts, 6)],
    discard: discard ?? const [],
    players: players,
    seatOrder: seatOrder,
    phase: phase,
    turnPlayerId: turnPlayerId,
    drawnCard: drawnCard,
    pending: pending,
    initialPeeksDone: {for (final uid in seatOrder) uid: true},
    cutterId: cutterId,
    firstFlippedRank: 5,
    totalRounds: totalRounds,
    roundIndex: roundIndex,
    roundPoints: roundPoints ?? {for (final uid in seatOrder) uid: 0},
    gamesWon: gamesWon ?? {for (final uid in seatOrder) uid: 0},
    lastDiscardRank: lastDiscardRank,
    lastDiscardBy: lastDiscardBy,
  );
}
