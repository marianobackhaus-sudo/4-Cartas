import 'card.dart';
import 'game_phase.dart';
import 'pending_action.dart';
import 'player_state.dart';

class GameState {
  final List<GameCard> deck;
  final List<GameCard> discard;
  final Map<String, PlayerState> players;
  final List<String> seatOrder;

  final GamePhase phase;
  final String turnPlayerId;
  final GameCard? drawnCard;
  final PendingAction? pending;

  final Map<String, bool> initialPeeksDone;

  final String? cutterId;
  final bool goldenRound;
  final String? roundWinnerUid;

  final int firstFlippedRank;
  final int totalRounds;
  final int roundIndex; // 0-based within current game
  final Map<String, int> roundPoints; // accumulated across rounds in the current game

  final int gameIndex; // 0-based within the match
  final Map<String, int> gamesWon;
  final String? matchWinnerUid;

  final int? lastDiscardRank;
  final String? lastDiscardBy;

  /// Penalty points accumulated for failed mirror attempts in the current
  /// round. Added to the player's score at reveal.
  final Map<String, int> mirrorPenalty;

  /// True when a cut was announced while the player was holding a drawn card.
  /// The cut fires automatically the moment the drawn card is resolved.
  final bool cutPending;

  const GameState({
    required this.deck,
    required this.discard,
    required this.players,
    required this.seatOrder,
    required this.phase,
    required this.turnPlayerId,
    this.drawnCard,
    this.pending,
    required this.initialPeeksDone,
    this.cutterId,
    this.goldenRound = false,
    this.roundWinnerUid,
    required this.firstFlippedRank,
    required this.totalRounds,
    this.roundIndex = 0,
    required this.roundPoints,
    this.gameIndex = 0,
    required this.gamesWon,
    this.matchWinnerUid,
    this.lastDiscardRank,
    this.lastDiscardBy,
    this.mirrorPenalty = const {},
    this.cutPending = false,
  });

  String opponentOf(String uid) => seatOrder.firstWhere((u) => u != uid);

  PlayerState player(String uid) => players[uid]!;

  GameState copyWith({
    List<GameCard>? deck,
    List<GameCard>? discard,
    Map<String, PlayerState>? players,
    List<String>? seatOrder,
    GamePhase? phase,
    String? turnPlayerId,
    Object? drawnCard = _sentinel,
    Object? pending = _sentinel,
    Map<String, bool>? initialPeeksDone,
    Object? cutterId = _sentinel,
    bool? goldenRound,
    Object? roundWinnerUid = _sentinel,
    int? firstFlippedRank,
    int? totalRounds,
    int? roundIndex,
    Map<String, int>? roundPoints,
    int? gameIndex,
    Map<String, int>? gamesWon,
    Object? matchWinnerUid = _sentinel,
    Object? lastDiscardRank = _sentinel,
    Object? lastDiscardBy = _sentinel,
    Map<String, int>? mirrorPenalty,
    bool? cutPending,
  }) {
    return GameState(
      deck: deck ?? this.deck,
      discard: discard ?? this.discard,
      players: players ?? this.players,
      seatOrder: seatOrder ?? this.seatOrder,
      phase: phase ?? this.phase,
      turnPlayerId: turnPlayerId ?? this.turnPlayerId,
      drawnCard:
          identical(drawnCard, _sentinel) ? this.drawnCard : drawnCard as GameCard?,
      pending: identical(pending, _sentinel) ? this.pending : pending as PendingAction?,
      initialPeeksDone: initialPeeksDone ?? this.initialPeeksDone,
      cutterId:
          identical(cutterId, _sentinel) ? this.cutterId : cutterId as String?,
      goldenRound: goldenRound ?? this.goldenRound,
      roundWinnerUid: identical(roundWinnerUid, _sentinel)
          ? this.roundWinnerUid
          : roundWinnerUid as String?,
      firstFlippedRank: firstFlippedRank ?? this.firstFlippedRank,
      totalRounds: totalRounds ?? this.totalRounds,
      roundIndex: roundIndex ?? this.roundIndex,
      roundPoints: roundPoints ?? this.roundPoints,
      gameIndex: gameIndex ?? this.gameIndex,
      gamesWon: gamesWon ?? this.gamesWon,
      matchWinnerUid: identical(matchWinnerUid, _sentinel)
          ? this.matchWinnerUid
          : matchWinnerUid as String?,
      lastDiscardRank: identical(lastDiscardRank, _sentinel)
          ? this.lastDiscardRank
          : lastDiscardRank as int?,
      lastDiscardBy: identical(lastDiscardBy, _sentinel)
          ? this.lastDiscardBy
          : lastDiscardBy as String?,
      mirrorPenalty: mirrorPenalty ?? this.mirrorPenalty,
      cutPending: cutPending ?? this.cutPending,
    );
  }

  Map<String, dynamic> toJson() => {
        'deck': deck.map((c) => c.toJson()).toList(),
        'discard': discard.map((c) => c.toJson()).toList(),
        'players': players.map((k, v) => MapEntry(k, v.toJson())),
        'seatOrder': seatOrder,
        'phase': phase.code,
        'turnPlayerId': turnPlayerId,
        'drawnCard': drawnCard?.toJson(),
        'pending': pending?.toJson(),
        'initialPeeksDone': initialPeeksDone,
        'cutterId': cutterId,
        'goldenRound': goldenRound,
        'roundWinnerUid': roundWinnerUid,
        'firstFlippedRank': firstFlippedRank,
        'totalRounds': totalRounds,
        'roundIndex': roundIndex,
        'roundPoints': roundPoints,
        'gameIndex': gameIndex,
        'gamesWon': gamesWon,
        'matchWinnerUid': matchWinnerUid,
        'lastDiscardRank': lastDiscardRank,
        'lastDiscardBy': lastDiscardBy,
        'mirrorPenalty': mirrorPenalty,
        'cutPending': cutPending,
      };

  factory GameState.fromJson(Map<String, dynamic> json) => GameState(
        deck: (json['deck'] as List<dynamic>)
            .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        discard: (json['discard'] as List<dynamic>)
            .map((e) => GameCard.fromJson(e as Map<String, dynamic>))
            .toList(),
        players: (json['players'] as Map<String, dynamic>).map(
          (k, v) =>
              MapEntry(k, PlayerState.fromJson(v as Map<String, dynamic>)),
        ),
        seatOrder: (json['seatOrder'] as List<dynamic>).cast<String>(),
        phase: GamePhaseCode.fromCode(json['phase'] as String),
        turnPlayerId: json['turnPlayerId'] as String,
        drawnCard: json['drawnCard'] == null
            ? null
            : GameCard.fromJson(json['drawnCard'] as Map<String, dynamic>),
        pending:
            PendingAction.fromJson(json['pending'] as Map<String, dynamic>?),
        initialPeeksDone:
            (json['initialPeeksDone'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, v as bool),
        ),
        cutterId: json['cutterId'] as String?,
        goldenRound: (json['goldenRound'] as bool?) ?? false,
        roundWinnerUid: json['roundWinnerUid'] as String?,
        firstFlippedRank: json['firstFlippedRank'] as int,
        totalRounds: json['totalRounds'] as int,
        roundIndex: (json['roundIndex'] as int?) ?? 0,
        roundPoints: (json['roundPoints'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        gameIndex: (json['gameIndex'] as int?) ?? 0,
        gamesWon: (json['gamesWon'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as num).toInt()),
        ),
        matchWinnerUid: json['matchWinnerUid'] as String?,
        lastDiscardRank: json['lastDiscardRank'] as int?,
        lastDiscardBy: json['lastDiscardBy'] as String?,
        mirrorPenalty:
            (json['mirrorPenalty'] as Map<String, dynamic>?)?.map(
                  (k, v) => MapEntry(k, (v as num).toInt()),
                ) ??
                const {},
        cutPending: (json['cutPending'] as bool?) ?? false,
      );
}

const _sentinel = Object();
