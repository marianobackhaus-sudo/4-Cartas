import 'package:flutter_test/flutter_test.dart';
import 'package:juego_cartas_4/engine/models/card.dart';
import 'package:juego_cartas_4/engine/models/hand_slot.dart';
import 'package:juego_cartas_4/engine/models/player_state.dart';
import 'package:juego_cartas_4/engine/scoring.dart';

import '_helpers.dart';

void main() {
  group('scoreHand', () {
    test('sums regular card values', () {
      final player = PlayerState(uid: 'A', slots: [
        HandSlot(card: const GameCard.regular(Suit.hearts, 1)),  // 1
        HandSlot(card: const GameCard.regular(Suit.spades, 5)),  // 5
        HandSlot(card: const GameCard.regular(Suit.clubs, 13)), // 13
        HandSlot(card: const GameCard.regular(Suit.diamonds, 7)), // 7
      ]);
      expect(scoreHand(player), 26);
    });

    test('jokers contribute -2 each', () {
      final player = PlayerState(uid: 'A', slots: [
        HandSlot(card: const GameCard.joker()),
        HandSlot(card: const GameCard.joker()),
        HandSlot(card: const GameCard.regular(Suit.hearts, 10)),
        HandSlot(card: const GameCard.regular(Suit.spades, 1)),
      ]);
      expect(scoreHand(player), -2 + -2 + 10 + 1);
    });
  });

  group('roundWinnerUid / resolveRoundOutcome', () {
    test('plain lowest wins when no cutter', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.hearts, 3),
            const GameCard.regular(Suit.hearts, 4),
          ], // 10
          'B': [
            const GameCard.regular(Suit.spades, 5),
            const GameCard.regular(Suit.spades, 6),
            const GameCard.regular(Suit.spades, 7),
            const GameCard.regular(Suit.spades, 8),
          ], // 26
        },
      );
      expect(roundWinnerUid(state), 'A');
      expect(resolveRoundOutcome(state), 'A');
    });

    test('tie returns null (golden round trigger)', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.hearts, 3),
            const GameCard.regular(Suit.hearts, 4),
          ], // 10
          'B': [
            const GameCard.regular(Suit.spades, 1),
            const GameCard.regular(Suit.spades, 2),
            const GameCard.regular(Suit.spades, 3),
            const GameCard.regular(Suit.spades, 4),
          ], // 10
        },
      );
      expect(roundWinnerUid(state), null);
      expect(resolveRoundOutcome(state), null);
    });

    test('cutter wins only if strictly lower', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 1),
          ], // 5
          'B': [
            const GameCard.regular(Suit.spades, 1),
            const GameCard.regular(Suit.spades, 1),
            const GameCard.regular(Suit.spades, 1),
            const GameCard.regular(Suit.spades, 1),
          ], // 4
        },
        cutterId: 'A',
      );
      // A cut but B is strictly lower → B wins.
      expect(resolveRoundOutcome(state), 'B');
    });

    test('cutter with strictly lower score wins', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 1),
          ], // 4
          'B': [
            const GameCard.regular(Suit.spades, 2),
            const GameCard.regular(Suit.spades, 2),
            const GameCard.regular(Suit.spades, 2),
            const GameCard.regular(Suit.spades, 2),
          ], // 8
        },
        cutterId: 'A',
      );
      expect(resolveRoundOutcome(state), 'A');
    });

    test('cutter with equal score loses (golden, returns null)', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 1),
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.hearts, 3),
            const GameCard.regular(Suit.hearts, 4),
          ], // 10
          'B': [
            const GameCard.regular(Suit.spades, 1),
            const GameCard.regular(Suit.spades, 2),
            const GameCard.regular(Suit.spades, 3),
            const GameCard.regular(Suit.spades, 4),
          ], // 10
        },
        cutterId: 'A',
      );
      expect(resolveRoundOutcome(state), null);
    });
  });
}
