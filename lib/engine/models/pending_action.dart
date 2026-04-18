sealed class PendingAction {
  const PendingAction();

  Map<String, dynamic> toJson();

  static PendingAction? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final type = json['type'] as String;
    switch (type) {
      case 'peekOwn':
        return PendingPeekOwn(rank: json['rank'] as int);
      case 'peekOpponent':
        return PendingPeekOpponent(rank: json['rank'] as int);
      case 'swap':
        return PendingSwap(
          rank: json['rank'] as int,
          ownSlot: json['ownSlot'] as int?,
          opponentSlot: json['opponentSlot'] as int?,
        );
      case 'kingPeek':
        return PendingKingPeek(
          peekedOwnerUids: (json['peekedOwnerUids'] as List<dynamic>?)
                  ?.cast<String>() ??
              const [],
          peekedSlots:
              (json['peekedSlots'] as List<dynamic>?)?.cast<int>() ?? const [],
        );
      default:
        throw ArgumentError('Unknown pending type: $type');
    }
  }
}

class PendingPeekOwn extends PendingAction {
  final int rank;
  const PendingPeekOwn({required this.rank});
  @override
  Map<String, dynamic> toJson() => {'type': 'peekOwn', 'rank': rank};
}

class PendingPeekOpponent extends PendingAction {
  final int rank;
  const PendingPeekOpponent({required this.rank});
  @override
  Map<String, dynamic> toJson() => {'type': 'peekOpponent', 'rank': rank};
}

class PendingSwap extends PendingAction {
  final int rank; // 11 (J), 12 (Q), or 13 (K - after peek)
  final int? ownSlot;
  final int? opponentSlot;
  const PendingSwap({required this.rank, this.ownSlot, this.opponentSlot});

  PendingSwap copyWith({int? ownSlot, int? opponentSlot}) => PendingSwap(
        rank: rank,
        ownSlot: ownSlot ?? this.ownSlot,
        opponentSlot: opponentSlot ?? this.opponentSlot,
      );

  @override
  Map<String, dynamic> toJson() => {
        'type': 'swap',
        'rank': rank,
        'ownSlot': ownSlot,
        'opponentSlot': opponentSlot,
      };
}

class PendingKingPeek extends PendingAction {
  final List<String> peekedOwnerUids;
  final List<int> peekedSlots;

  const PendingKingPeek({
    this.peekedOwnerUids = const [],
    this.peekedSlots = const [],
  });

  PendingKingPeek addPeek(String ownerUid, int slotIndex) => PendingKingPeek(
        peekedOwnerUids: [...peekedOwnerUids, ownerUid],
        peekedSlots: [...peekedSlots, slotIndex],
      );

  bool get isComplete => peekedSlots.length >= 2;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'kingPeek',
        'peekedOwnerUids': peekedOwnerUids,
        'peekedSlots': peekedSlots,
      };
}
