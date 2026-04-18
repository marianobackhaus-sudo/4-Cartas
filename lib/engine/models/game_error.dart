enum GameErrorCode {
  notYourTurn,
  wrongPhase,
  noDrawnCard,
  alreadyDrawn,
  invalidSlot,
  invalidTarget,
  pendingNotResolved,
  cannotCutNow,
  invalidAction,
  deckEmpty,
  alreadyPeeked,
}

class GameError implements Exception {
  final GameErrorCode code;
  final String message;
  const GameError(this.code, this.message);

  @override
  String toString() => 'GameError(${code.name}): $message';
}
