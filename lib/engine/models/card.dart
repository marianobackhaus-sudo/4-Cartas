enum Suit { hearts, diamonds, clubs, spades }

extension SuitCode on Suit {
  String get code {
    switch (this) {
      case Suit.hearts:
        return 'H';
      case Suit.diamonds:
        return 'D';
      case Suit.clubs:
        return 'C';
      case Suit.spades:
        return 'S';
    }
  }

  static Suit fromCode(String code) {
    switch (code) {
      case 'H':
        return Suit.hearts;
      case 'D':
        return Suit.diamonds;
      case 'C':
        return Suit.clubs;
      case 'S':
        return Suit.spades;
      default:
        throw ArgumentError('Unknown suit: $code');
    }
  }
}

class GameCard {
  final Suit? suit;
  final int rank;
  final bool isJoker;

  const GameCard.regular(Suit this.suit, this.rank)
      : assert(rank >= 1 && rank <= 13),
        isJoker = false;

  const GameCard.joker()
      : suit = null,
        rank = 0,
        isJoker = true;

  int get value => isJoker ? -2 : rank;

  Map<String, dynamic> toJson() => {
        if (suit != null) 's': suit!.code,
        'r': rank,
        if (isJoker) 'j': true,
      };

  factory GameCard.fromJson(Map<String, dynamic> json) {
    if (json['j'] == true) return const GameCard.joker();
    return GameCard.regular(
      SuitCode.fromCode(json['s'] as String),
      json['r'] as int,
    );
  }

  @override
  String toString() {
    if (isJoker) return 'JKR';
    String r;
    switch (rank) {
      case 1:
        r = 'A';
        break;
      case 11:
        r = 'J';
        break;
      case 12:
        r = 'Q';
        break;
      case 13:
        r = 'K';
        break;
      default:
        r = '$rank';
    }
    return '$r${suit!.code}';
  }

  @override
  bool operator ==(Object other) =>
      other is GameCard &&
      suit == other.suit &&
      rank == other.rank &&
      isJoker == other.isJoker;

  @override
  int get hashCode => Object.hash(suit, rank, isJoker);
}
