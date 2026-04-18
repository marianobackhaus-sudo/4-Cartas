import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:juego_cartas_4/engine/deck.dart';
import 'package:juego_cartas_4/engine/models/card.dart';

void main() {
  group('buildDeck', () {
    test('returns 54 cards (52 + 2 jokers)', () {
      final deck = buildDeck();
      expect(deck.length, 54);
    });

    test('contains all 52 regular poker cards', () {
      final deck = buildDeck();
      final regular = deck.where((c) => !c.isJoker).toList();
      expect(regular.length, 52);

      for (final suit in Suit.values) {
        for (var rank = 1; rank <= 13; rank++) {
          final match = regular.where(
            (c) => c.suit == suit && c.rank == rank,
          );
          expect(match.length, 1,
              reason: 'Missing or duplicate ${suit.code}$rank');
        }
      }
    });

    test('contains exactly 2 jokers', () {
      final deck = buildDeck();
      expect(deck.where((c) => c.isJoker).length, 2);
    });
  });

  group('shuffleDeck', () {
    test('returns same cards in different order (seeded)', () {
      final deck = buildDeck();
      final shuffled = shuffleDeck(deck, random: Random(42));
      expect(shuffled.length, deck.length);
      expect(shuffled.toSet(), deck.toSet());
      expect(shuffled, isNot(equals(deck)));
    });

    test('does not mutate input', () {
      final deck = buildDeck();
      final snapshot = List<GameCard>.of(deck);
      shuffleDeck(deck, random: Random(1));
      expect(deck, equals(snapshot));
    });
  });

  group('GameCard', () {
    test('joker value is -2', () {
      expect(const GameCard.joker().value, -2);
    });

    test('regular cards use rank as value', () {
      expect(const GameCard.regular(Suit.hearts, 1).value, 1);
      expect(const GameCard.regular(Suit.spades, 10).value, 10);
      expect(const GameCard.regular(Suit.clubs, 13).value, 13);
    });

    test('round-trips via toJson/fromJson', () {
      const king = GameCard.regular(Suit.diamonds, 13);
      expect(GameCard.fromJson(king.toJson()), equals(king));

      const joker = GameCard.joker();
      expect(GameCard.fromJson(joker.toJson()), equals(joker));
    });
  });
}
