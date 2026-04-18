import 'package:flutter_test/flutter_test.dart';
import 'package:juego_cartas_4/engine/models/card.dart';
import 'package:juego_cartas_4/engine/models/game_action.dart';
import 'package:juego_cartas_4/engine/models/game_error.dart';
import 'package:juego_cartas_4/engine/models/game_phase.dart';
import 'package:juego_cartas_4/engine/models/pending_action.dart';
import 'package:juego_cartas_4/engine/rules.dart';

import '_helpers.dart';

void main() {
  group('DrawFromDeck', () {
    test('moves top card from deck to drawnCard', () {
      final state = makeState(
        deck: const [
          GameCard.regular(Suit.hearts, 9),
          GameCard.regular(Suit.clubs, 6),
        ],
      );
      final next = apply(state, const DrawFromDeck('A'));
      expect(next.drawnCard, const GameCard.regular(Suit.clubs, 6));
      expect(next.deck.length, 1);
      expect(next.turnPlayerId, 'A', reason: 'Draw does not flip turn');
    });

    test('throws notYourTurn', () {
      final state = makeState();
      expect(
        () => apply(state, const DrawFromDeck('B')),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.notYourTurn)),
      );
    });

    test('throws alreadyDrawn if drawnCard present', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 5),
      );
      expect(
        () => apply(state, const DrawFromDeck('A')),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.alreadyDrawn)),
      );
    });
  });

  group('SwapDrawnWithSlot', () {
    test('swaps drawn with slot and flips turn, old card to discard', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 9),
      );
      final next = apply(state, const SwapDrawnWithSlot('A', 0));
      expect(next.drawnCard, null);
      expect(next.player('A').slots[0].card,
          const GameCard.regular(Suit.hearts, 9));
      expect(next.player('A').slots[0].knownToOwner, true);
      expect(next.discard.last, const GameCard.regular(Suit.hearts, 2));
      expect(next.turnPlayerId, 'B');
    });
  });

  group('DiscardDrawn', () {
    test('non-power rank: discards and flips turn', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 3),
      );
      final next = apply(state, const DiscardDrawn('A'));
      expect(next.drawnCard, null);
      expect(next.pending, null);
      expect(next.discard.last, const GameCard.regular(Suit.hearts, 3));
      expect(next.turnPlayerId, 'B');
    });

    test('rank 7 triggers PendingPeekOwn and keeps turn', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 7),
      );
      final next = apply(state, const DiscardDrawn('A'));
      expect(next.pending, isA<PendingPeekOwn>());
      expect(next.turnPlayerId, 'A');
    });

    test('rank 9 triggers PendingPeekOpponent', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 9),
      );
      final next = apply(state, const DiscardDrawn('A'));
      expect(next.pending, isA<PendingPeekOpponent>());
    });

    test('rank 12 triggers PendingSwap', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 12),
      );
      final next = apply(state, const DiscardDrawn('A'));
      expect(next.pending, isA<PendingSwap>());
    });

    test('rank 13 triggers PendingKingPeek', () {
      final state = makeState(
        drawnCard: const GameCard.regular(Suit.hearts, 13),
      );
      final next = apply(state, const DiscardDrawn('A'));
      expect(next.pending, isA<PendingKingPeek>());
    });

    test('joker does not trigger power', () {
      final state = makeState(drawnCard: const GameCard.joker());
      final next = apply(state, const DiscardDrawn('A'));
      expect(next.pending, null);
      expect(next.turnPlayerId, 'B');
    });
  });

  group('Cut', () {
    test('valid cut: sets cutterId, phase awaitingLastTurn, turn flips', () {
      final state = makeState();
      final next = apply(state, const Cut('A'));
      expect(next.cutterId, 'A');
      expect(next.phase, GamePhase.awaitingLastTurn);
      expect(next.turnPlayerId, 'B');
    });

    test('cut blocked while drawnCard present', () {
      final state = makeState(drawnCard: const GameCard.regular(Suit.hearts, 2));
      expect(
        () => apply(state, const Cut('A')),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.cannotCutNow)),
      );
    });

    test('after opponent last turn, phase → reveal', () {
      // Start in awaitingLastTurn where it is B's turn (A already cut).
      final cutState = makeState(
        phase: GamePhase.awaitingLastTurn,
        turnPlayerId: 'B',
        cutterId: 'A',
        drawnCard: const GameCard.regular(Suit.hearts, 3),
      );
      final next = apply(cutState, const DiscardDrawn('B'));
      expect(next.phase, GamePhase.reveal);
    });
  });

  group('CompleteInitialPeek', () {
    test('first peek stays in peekInitial, second transitions to turn', () {
      var state = makeState(phase: GamePhase.peekInitial)
          .copyWith(initialPeeksDone: {'A': false, 'B': false});
      state = apply(state, const CompleteInitialPeek('A'));
      expect(state.phase, GamePhase.peekInitial);
      state = apply(state, const CompleteInitialPeek('B'));
      expect(state.phase, GamePhase.turn);
    });

    test('cannot peek twice', () {
      var state = makeState(phase: GamePhase.peekInitial)
          .copyWith(initialPeeksDone: {'A': false, 'B': false});
      state = apply(state, const CompleteInitialPeek('A'));
      expect(
        () => apply(state, const CompleteInitialPeek('A')),
        throwsA(isA<GameError>().having(
            (e) => e.code, 'code', GameErrorCode.alreadyPeeked)),
      );
    });
  });

  group('setupInitialState', () {
    test('deals 4 cards each and flips starter', () {
      // 9 cards: 4+4 hands, 1 starter.
      final deck = [
        const GameCard.regular(Suit.hearts, 3), // starter (top)
        const GameCard.regular(Suit.hearts, 4),
        const GameCard.regular(Suit.hearts, 5),
        const GameCard.regular(Suit.hearts, 6),
        const GameCard.regular(Suit.hearts, 7),
        const GameCard.regular(Suit.clubs, 8),
        const GameCard.regular(Suit.clubs, 9),
        const GameCard.regular(Suit.clubs, 10),
        const GameCard.regular(Suit.clubs, 11),
      ];
      // removeLast picks from the end, so starter is deck.last after 8 deals.
      // Reorder so that position 8 (end) is the starter: we want the starter = 3.
      final state = setupInitialState(
        seatOrder: const ['A', 'B'],
        shuffledDeck: deck.reversed.toList(),
      );
      expect(state.players['A']!.slots.length, 4);
      expect(state.players['B']!.slots.length, 4);
      expect(state.discard.length, 1);
      expect(state.phase, GamePhase.peekInitial);
      expect(state.totalRounds, state.firstFlippedRank.clamp(1, 5));
    });
  });

  group('advanceFromReveal', () {
    test('tie → golden round, no accumulation, no index advance', () {
      final state = makeState(
        phase: GamePhase.reveal,
        hands: {
          'A': List.filled(4, const GameCard.regular(Suit.hearts, 2)), // 8
          'B': List.filled(4, const GameCard.regular(Suit.spades, 2)), // 8
        },
        roundIndex: 1,
      );
      final next = advanceFromReveal(state);
      expect(next.phase, GamePhase.roundEnd);
      expect(next.goldenRound, true);
      expect(next.roundIndex, 1);
      expect(next.roundPoints['A'], 0);
      expect(next.roundPoints['B'], 0);
    });

    test('winner → accumulates, advances round index', () {
      final state = makeState(
        phase: GamePhase.reveal,
        hands: {
          'A': List.filled(4, const GameCard.regular(Suit.hearts, 1)), // 4
          'B': List.filled(4, const GameCard.regular(Suit.spades, 5)), // 20
        },
        roundIndex: 0,
      );
      final next = advanceFromReveal(state);
      expect(next.phase, GamePhase.roundEnd);
      expect(next.roundWinnerUid, 'A');
      expect(next.roundIndex, 1);
      expect(next.roundPoints['A'], 4);
      expect(next.roundPoints['B'], 20);
    });

    test('last round with winner → gameEnd + gamesWon increments', () {
      final state = makeState(
        phase: GamePhase.reveal,
        hands: {
          'A': List.filled(4, const GameCard.regular(Suit.hearts, 1)), // 4
          'B': List.filled(4, const GameCard.regular(Suit.spades, 5)), // 20
        },
        roundIndex: 2,
        totalRounds: 3,
      );
      final next = advanceFromReveal(state);
      expect(next.phase, GamePhase.gameEnd);
      expect(next.gamesWon['A'], 1);
      expect(next.gamesWon['B'], 0);
    });

    test('two game wins → matchEnd with matchWinnerUid', () {
      final state = makeState(
        phase: GamePhase.reveal,
        hands: {
          'A': List.filled(4, const GameCard.regular(Suit.hearts, 1)), // 4
          'B': List.filled(4, const GameCard.regular(Suit.spades, 5)), // 20
        },
        roundIndex: 2,
        totalRounds: 3,
        gamesWon: {'A': 1, 'B': 0},
      );
      final next = advanceFromReveal(state);
      expect(next.phase, GamePhase.matchEnd);
      expect(next.matchWinnerUid, 'A');
    });
  });
}

