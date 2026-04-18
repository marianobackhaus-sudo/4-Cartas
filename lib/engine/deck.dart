import 'dart:math';

import 'models/card.dart';

List<GameCard> buildDeck() {
  final cards = <GameCard>[];
  for (final suit in Suit.values) {
    for (var rank = 1; rank <= 13; rank++) {
      cards.add(GameCard.regular(suit, rank));
    }
  }
  cards.add(const GameCard.joker());
  cards.add(const GameCard.joker());
  return cards;
}

List<GameCard> shuffleDeck(List<GameCard> deck, {Random? random}) {
  final rng = random ?? Random.secure();
  final copy = List<GameCard>.of(deck);
  copy.shuffle(rng);
  return copy;
}
