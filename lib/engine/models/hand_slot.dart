import 'card.dart';

class HandSlot {
  final GameCard card;
  final bool faceDown;
  final bool knownToOwner;

  const HandSlot({
    required this.card,
    this.faceDown = true,
    this.knownToOwner = false,
  });

  HandSlot copyWith({GameCard? card, bool? faceDown, bool? knownToOwner}) {
    return HandSlot(
      card: card ?? this.card,
      faceDown: faceDown ?? this.faceDown,
      knownToOwner: knownToOwner ?? this.knownToOwner,
    );
  }

  Map<String, dynamic> toJson() => {
        'card': card.toJson(),
        'faceDown': faceDown,
        'knownToOwner': knownToOwner,
      };

  factory HandSlot.fromJson(Map<String, dynamic> json) => HandSlot(
        card: GameCard.fromJson(json['card'] as Map<String, dynamic>),
        faceDown: (json['faceDown'] as bool?) ?? true,
        knownToOwner: (json['knownToOwner'] as bool?) ?? false,
      );
}
