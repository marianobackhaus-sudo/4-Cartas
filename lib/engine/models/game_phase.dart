enum GamePhase {
  setup,
  peekInitial,
  turn,
  awaitingLastTurn,
  reveal,
  roundEnd,
  gameEnd,
  matchEnd,
}

extension GamePhaseCode on GamePhase {
  String get code => name;

  static GamePhase fromCode(String code) {
    return GamePhase.values.firstWhere(
      (p) => p.name == code,
      orElse: () =>
          throw ArgumentError('Unknown GamePhase code: $code'),
    );
  }
}
