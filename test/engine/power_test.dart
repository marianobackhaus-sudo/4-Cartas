import 'package:flutter_test/flutter_test.dart';
import 'package:juego_cartas_4/engine/models/card.dart';
import 'package:juego_cartas_4/engine/models/game_action.dart';
import 'package:juego_cartas_4/engine/models/game_error.dart';
import 'package:juego_cartas_4/engine/models/pending_action.dart';
import 'package:juego_cartas_4/engine/power_resolver.dart';

import '_helpers.dart';

void main() {
  group('PendingPeekOwn / PendingPeekOpponent (7, 8, 9, 10)', () {
    test('PeekOwn clears pending and flips turn (no hand mutation)', () {
      final state = makeState(pending: const PendingPeekOwn(rank: 7));
      final next = resolvePower(state, const ResolvePower('A'));
      expect(next.pending, null);
      expect(next.turnPlayerId, 'B');
    });

    test('PeekOpponent clears pending and flips turn', () {
      final state = makeState(pending: const PendingPeekOpponent(rank: 9));
      final next = resolvePower(state, const ResolvePower('A'));
      expect(next.pending, null);
      expect(next.turnPlayerId, 'B');
    });
  });

  group('PendingSwap (J, Q)', () {
    test('swaps slots between players and flips turn', () {
      final state = makeState(
        pending: const PendingSwap(rank: 11),
        hands: {
          'A': [
            const GameCard.regular(Suit.hearts, 2),
            const GameCard.regular(Suit.hearts, 3),
            const GameCard.regular(Suit.hearts, 4),
            const GameCard.regular(Suit.hearts, 5),
          ],
          'B': [
            const GameCard.regular(Suit.spades, 8),
            const GameCard.regular(Suit.spades, 9),
            const GameCard.regular(Suit.spades, 10),
            const GameCard.regular(Suit.spades, 11),
          ],
        },
      );
      final next = resolvePower(
        state,
        const ResolvePower('A', ownSlot: 0, opponentSlot: 3),
      );
      expect(next.player('A').slots[0].card,
          const GameCard.regular(Suit.spades, 11));
      expect(next.player('B').slots[3].card,
          const GameCard.regular(Suit.hearts, 2));
      expect(next.pending, null);
      expect(next.turnPlayerId, 'B');
    });

    test('rejects missing slot arguments', () {
      final state = makeState(pending: const PendingSwap(rank: 12));
      expect(
        () => resolvePower(state, const ResolvePower('A', ownSlot: 0)),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.invalidTarget)),
      );
    });
  });

  group('PendingKingPeek (K)', () {
    test('two sequential peeks accumulate, then swap completes', () {
      final state = makeState(pending: const PendingKingPeek());

      // 1st peek — own slot
      final afterPeek1 = resolvePower(
        state,
        const ResolvePower('A', peekOwnerUid: 'A', peekSlot: 1),
      );
      expect(afterPeek1.pending, isA<PendingKingPeek>());
      expect((afterPeek1.pending as PendingKingPeek).isComplete, false);
      expect(afterPeek1.turnPlayerId, 'A');

      // 2nd peek — opponent slot
      final afterPeek2 = resolvePower(
        afterPeek1,
        const ResolvePower('A', peekOwnerUid: 'B', peekSlot: 2),
      );
      expect((afterPeek2.pending as PendingKingPeek).isComplete, true);

      // Decide swap = true.
      final done = resolvePower(
        afterPeek2,
        const ResolvePower('A',
            kingDecideSwap: true, ownSlot: 1, opponentSlot: 2),
      );
      expect(done.pending, null);
      expect(done.turnPlayerId, 'B');
    });

    test('decide no-swap clears pending and flips turn', () {
      final state = makeState(
        pending: const PendingKingPeek(
          peekedOwnerUids: ['A', 'B'],
          peekedSlots: [0, 1],
        ),
      );
      final next = resolvePower(
        state,
        const ResolvePower('A', kingDecideSwap: false),
      );
      expect(next.pending, null);
      expect(next.turnPlayerId, 'B');
    });

    test('peek step rejects missing peekOwnerUid/peekSlot', () {
      final state = makeState(pending: const PendingKingPeek());
      expect(
        () => resolvePower(state, const ResolvePower('A')),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.invalidTarget)),
      );
    });
  });

  test('resolvePower rejects when no pending', () {
    final state = makeState();
    expect(
      () => resolvePower(state, const ResolvePower('A')),
      throwsA(isA<GameError>().having(
          (e) => e.code, 'code', GameErrorCode.invalidAction)),
    );
  });

  test('resolvePower rejects non-turn player', () {
    final state = makeState(pending: const PendingPeekOwn(rank: 7));
    expect(
      () => resolvePower(state, const ResolvePower('B')),
      throwsA(isA<GameError>().having(
          (e) => e.code, 'code', GameErrorCode.notYourTurn)),
    );
  });
}
