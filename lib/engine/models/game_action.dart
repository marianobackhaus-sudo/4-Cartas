sealed class GameAction {
  final String uid;
  const GameAction(this.uid);
}

class CompleteInitialPeek extends GameAction {
  const CompleteInitialPeek(super.uid);
}

class DrawFromDeck extends GameAction {
  const DrawFromDeck(super.uid);
}

class SwapDrawnWithSlot extends GameAction {
  final int slotIndex;
  const SwapDrawnWithSlot(super.uid, this.slotIndex);
}

class DiscardDrawn extends GameAction {
  const DiscardDrawn(super.uid);
}

class ResolvePower extends GameAction {
  final int? ownSlot;
  final int? opponentSlot;
  final String? peekOwnerUid;
  final int? peekSlot;
  final bool? kingDecideSwap;

  const ResolvePower(
    super.uid, {
    this.ownSlot,
    this.opponentSlot,
    this.peekOwnerUid,
    this.peekSlot,
    this.kingDecideSwap,
  });
}

class Cut extends GameAction {
  const Cut(super.uid);
}

class MirrorAttempt extends GameAction {
  final int slotIndex;
  const MirrorAttempt(super.uid, this.slotIndex);
}
