import 'models/game_state.dart';
import 'models/player_state.dart';

int scoreHand(PlayerState player) => player.handScore;

/// Full round score = handScore + mirrorPenalty. Used everywhere rounds are
/// compared / accumulated.
int scoreHandWithPenalty(GameState state, String uid) =>
    scoreHand(state.player(uid)) + (state.mirrorPenalty[uid] ?? 0);

/// Returns the uid of the round winner, or null if tied.
String? roundWinnerUid(GameState state) {
  final a = state.seatOrder[0];
  final b = state.seatOrder[1];
  final scoreA = scoreHandWithPenalty(state, a);
  final scoreB = scoreHandWithPenalty(state, b);

  if (scoreA < scoreB) return a;
  if (scoreB < scoreA) return b;
  return null;
}

/// Applies the cut rule: cutter wins only if strictly lower than opponent.
/// Returns uid of round winner, or null if tied (golden round).
String? resolveRoundOutcome(GameState state) {
  final a = state.seatOrder[0];
  final b = state.seatOrder[1];
  final scoreA = scoreHandWithPenalty(state, a);
  final scoreB = scoreHandWithPenalty(state, b);

  final cutter = state.cutterId;
  if (cutter == null) {
    // No cut (e.g. deck ran out or direct reveal): plain lowest wins; tie -> golden.
    if (scoreA < scoreB) return a;
    if (scoreB < scoreA) return b;
    return null;
  }

  final opponent = state.opponentOf(cutter);
  final cutterScore = scoreHandWithPenalty(state, cutter);
  final opponentScore = scoreHandWithPenalty(state, opponent);

  if (cutterScore < opponentScore) return cutter;
  if (cutterScore > opponentScore) return opponent;
  // Tie -> golden round
  return null;
}
