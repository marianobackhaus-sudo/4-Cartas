import 'package:flutter_test/flutter_test.dart';
import 'package:juego_cartas_4/engine/mirror_resolver.dart';
import 'package:juego_cartas_4/engine/models/card.dart';
import 'package:juego_cartas_4/engine/models/game_action.dart';
import 'package:juego_cartas_4/engine/models/game_error.dart';
import 'package:juego_cartas_4/engine/models/pending_action.dart';

import '_helpers.dart';

void main() {
  group('MirrorAttempt — match', () {
    test('removes slot and pushes its card to discard', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 7),
            const GameCard.regular(Suit.clubs, 3),
            const GameCard.regular(Suit.diamonds, 4),
            const GameCard.regular(Suit.spades, 5),
          ],
          'B': [
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.clubs, 3),
            const GameCard.regular(Suit.diamonds, 4),
            const GameCard.regular(Suit.spades, 5),
          ],
        },
        lastDiscardRank: 7,
      );
      final next = resolveMirror(state, const MirrorAttempt('A', 0));
      expect(next.player('A').slots.length, 3);
      expect(next.discard.last, const GameCard.regular(Suit.hearts, 7));
      expect(next.lastDiscardRank, 7);
      expect(next.lastDiscardBy, 'A');
      expect(next.turnPlayerId, 'A', reason: 'Mirror does not flip turn');
    });
  });

  group('MirrorAttempt — miss', () {
    test('hand stays untouched, +5 to mirrorPenalty', () {
      final state = makeState(
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 10),
            const GameCard.regular(Suit.clubs, 3),
            const GameCard.regular(Suit.diamonds, 4),
            const GameCard.regular(Suit.spades, 5),
          ],
          'B': [
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.clubs, 3),
            const GameCard.regular(Suit.diamonds, 4),
            const GameCard.regular(Suit.spades, 5),
          ],
        },
        lastDiscardRank: 7,
      );
      final next = resolveMirror(state, const MirrorAttempt('A', 0));
      expect(next.player('A').slots.length, 4, reason: 'hand stays at 4');
      expect(next.player('A').slots[0].faceDown, true,
          reason: 'slot stays hidden');
      expect(next.mirrorPenalty['A'], 5);
      expect(next.mirrorPenalty['B'] ?? 0, 0);
    });

    test('consecutive misses accumulate', () {
      final state = makeState(
        hands: {
          'A': List.filled(4, const GameCard.regular(Suit.hearts, 3)),
          'B': List.filled(4, const GameCard.regular(Suit.spades, 3)),
        },
        lastDiscardRank: 7,
        turnPlayerId: 'B',
      );
      var next = resolveMirror(state, const MirrorAttempt('A', 0));
      next = resolveMirror(next, const MirrorAttempt('A', 1));
      expect(next.mirrorPenalty['A'], 10);
    });
  });

  group('MirrorAttempt — guards', () {
    test('requires lastDiscardRank', () {
      final state = makeState(lastDiscardRank: null);
      expect(
        () => resolveMirror(state, const MirrorAttempt('A', 0)),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.invalidAction)),
      );
    });

    test('blocked while pending power', () {
      final state = makeState(
        pending: const PendingPeekOwn(rank: 7),
        lastDiscardRank: 7,
      );
      expect(
        () => resolveMirror(state, const MirrorAttempt('B', 0)),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.pendingNotResolved)),
      );
    });

    test('opponent can mirror (not bound to turn)', () {
      final state = makeState(
        turnPlayerId: 'A',
        lastDiscardRank: 3,
      );
      // Player B attempts a mirror on their own matching slot.
      final next = resolveMirror(state, const MirrorAttempt('B', 1));
      expect(next.player('B').slots.length, 3);
      expect(next.turnPlayerId, 'A');
    });
  });
}
