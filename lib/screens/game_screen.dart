import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../data/room_doc.dart';
import '../engine/models/game_phase.dart';
import '../engine/models/game_state.dart';
import '../engine/models/pending_action.dart';
import '../state/auth_providers.dart';
import '../state/game_controller.dart';
import '../state/room_providers.dart';
import '../widgets/action_bar.dart';
import '../widgets/deck_and_discard_widget.dart';
import '../widgets/mirror_button.dart';
import '../widgets/opponent_hand_widget.dart';
import '../widgets/peek_overlay.dart';
import '../widgets/player_hand_widget.dart';
import '../widgets/power_prompt.dart';
import '../widgets/score_panel.dart';
import '../widgets/turn_banner.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.roomCode});

  final String roomCode;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  int? _selectedOwn;
  int? _selectedOpp;
  final Set<int> _peekOwnReveal = {};
  final Set<int> _peekOppReveal = {};

  void _resetSelection() {
    setState(() {
      _selectedOwn = null;
      _selectedOpp = null;
      _peekOwnReveal.clear();
      _peekOppReveal.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));
    final uid = ref.watch(currentUserIdProvider).asData?.value;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgBase, AppColors.bgTable],
          ),
        ),
        child: SafeArea(
          child: roomAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('Error: $e', style: AppText.body)),
            data: (room) {
              if (room == null) {
                return const Center(
                    child: Text('Sala no encontrada', style: AppText.title));
              }
              final game = room.game;
              if (game == null || uid == null) {
                return const Center(child: CircularProgressIndicator());
              }
              if (game.phase == GamePhase.matchEnd) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.go('/result/${widget.roomCode}');
                  }
                });
              }
              return _GameBody(
                roomCode: widget.roomCode,
                room: room,
                game: game,
                myUid: uid,
                selectedOwn: _selectedOwn,
                selectedOpp: _selectedOpp,
                peekOwnReveal: _peekOwnReveal,
                peekOppReveal: _peekOppReveal,
                onSelectOwn: (i) {
                  setState(() {
                    _selectedOwn = _selectedOwn == i ? null : i;
                  });
                },
                onSelectOpp: (i) {
                  setState(() {
                    _selectedOpp = _selectedOpp == i ? null : i;
                  });
                },
                onPeekOwn: (i) {
                  setState(() {
                    if (_peekOwnReveal.contains(i)) {
                      _peekOwnReveal.remove(i);
                    } else {
                      _peekOwnReveal.add(i);
                    }
                  });
                },
                onPeekOpp: (i) {
                  setState(() {
                    if (_peekOppReveal.contains(i)) {
                      _peekOppReveal.remove(i);
                    } else {
                      _peekOppReveal.add(i);
                    }
                  });
                },
                resetSelection: _resetSelection,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GameBody extends ConsumerWidget {
  const _GameBody({
    required this.roomCode,
    required this.room,
    required this.game,
    required this.myUid,
    required this.selectedOwn,
    required this.selectedOpp,
    required this.peekOwnReveal,
    required this.peekOppReveal,
    required this.onSelectOwn,
    required this.onSelectOpp,
    required this.onPeekOwn,
    required this.onPeekOpp,
    required this.resetSelection,
  });

  final String roomCode;
  final RoomDoc room;
  final GameState game;
  final String myUid;
  final int? selectedOwn;
  final int? selectedOpp;
  final Set<int> peekOwnReveal;
  final Set<int> peekOppReveal;
  final ValueChanged<int> onSelectOwn;
  final ValueChanged<int> onSelectOpp;
  final ValueChanged<int> onPeekOwn;
  final ValueChanged<int> onPeekOpp;
  final VoidCallback resetSelection;

  GameController _ctrl(WidgetRef ref) =>
      ref.read(gameControllerProvider(roomCode));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oppUid = game.opponentOf(myUid);
    final me = game.player(myUid);
    final opp = game.player(oppUid);
    final isMyTurn = game.turnPlayerId == myUid;
    final pending = game.pending;
    final pendingIsMine = pending != null && isMyTurn;

    final showPeekInitial =
        game.phase == GamePhase.peekInitial &&
            (game.initialPeeksDone[myUid] ?? false) == false;

    final revealAll = game.phase == GamePhase.reveal ||
        game.phase == GamePhase.roundEnd ||
        game.phase == GamePhase.gameEnd;

    return Stack(
      children: [
        Column(
          children: [
            TurnBanner(
              isMyTurn: isMyTurn,
              label: _turnLabel(game, room, myUid),
            ),
            ScorePanel(
              roundIndex: game.roundIndex,
              totalRounds: game.totalRounds,
              gameIndex: game.gameIndex,
              myGamesWon: game.gamesWon[myUid] ?? 0,
              oppGamesWon: game.gamesWon[oppUid] ?? 0,
              goldenRound: game.goldenRound,
            ),
            const SizedBox(height: AppSpacing.base),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                children: [
                  Text(_nick(room, oppUid).toUpperCase(),
                      style: AppText.caption),
                  const SizedBox(height: AppSpacing.sm),
                  OpponentHandWidget(
                    slots: opp.slots,
                    revealAll: revealAll,
                    peekRevealIndices: peekOppReveal,
                    highlightedIndices: _oppHighlights(pendingIsMine, pending),
                    selectedIndex: selectedOpp,
                    onTapSlot: _oppTapHandler(pendingIsMine, pending),
                  ),
                ],
              ),
            ),
            const Spacer(),
            DeckAndDiscardWidget(
              deckCount: game.deck.length,
              topDiscard: game.discard.isEmpty ? null : game.discard.last,
              drawnCard: game.drawnCard,
              canDraw: isMyTurn &&
                  game.drawnCard == null &&
                  pending == null &&
                  (game.phase == GamePhase.turn ||
                      game.phase == GamePhase.awaitingLastTurn),
              canSwap: isMyTurn && game.drawnCard != null,
              canDiscard: isMyTurn && game.drawnCard != null,
              onDrawTap: () async {
                resetSelection();
                await _runAction(context, () => _ctrl(ref).drawFromDeck(myUid));
              },
              onDiscardTap: () async {
                resetSelection();
                await _runAction(
                    context, () => _ctrl(ref).discardDrawn(myUid));
              },
            ),
            const Spacer(),
            if (pendingIsMine)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: PowerPrompt(pending: pending),
              ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.base),
              child: Column(
                children: [
                  PlayerHandWidget(
                    slots: me.slots,
                    selectedIndex: selectedOwn,
                    peekRevealIndices: peekOwnReveal,
                    highlightedIndices: _ownHighlights(isMyTurn, pending),
                    onTapSlot: _ownTapHandler(
                        context, ref, isMyTurn, pending, game),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_nick(room, myUid).toUpperCase(),
                      style: AppText.caption),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildActionBar(context, ref),
          ],
        ),
        // Mirror FAB
        Positioned(
          right: AppSpacing.base,
          bottom: 92,
          child: MirrorButton(
            enabled: game.lastDiscardRank != null &&
                game.pending == null &&
                (game.phase == GamePhase.turn ||
                    game.phase == GamePhase.awaitingLastTurn) &&
                selectedOwn != null,
            onTap: () async {
              final slot = selectedOwn;
              if (slot == null) return;
              resetSelection();
              await _runAction(
                  context, () => _ctrl(ref).mirrorAttempt(myUid, slot));
            },
          ),
        ),
        // Peek initial overlay
        if (showPeekInitial)
          PeekOverlay(
            slots: me.slots,
            onConfirm: () async {
              await _runAction(
                  context, () => _ctrl(ref).completeInitialPeek(myUid));
            },
          ),
        // Round/game end overlays
        if (game.phase == GamePhase.reveal)
          _RevealOverlay(
            onContinue: () async {
              await _runAction(context, () => _ctrl(ref).advanceReveal());
            },
            game: game,
            myUid: myUid,
          ),
        if (game.phase == GamePhase.roundEnd)
          _RoundEndOverlay(
            game: game,
            myUid: myUid,
            isHost: room.hostId == myUid,
            onNext: () async {
              await _runAction(context, () => _ctrl(ref).nextRound());
            },
          ),
        if (game.phase == GamePhase.gameEnd)
          _GameEndOverlay(
            game: game,
            myUid: myUid,
            isHost: room.hostId == myUid,
            onNext: () async {
              await _runAction(context, () => _ctrl(ref).nextGame());
            },
          ),
      ],
    );
  }

  String _turnLabel(GameState game, RoomDoc room, String myUid) {
    switch (game.phase) {
      case GamePhase.peekInitial:
        return 'ESPIANDO CARTAS INICIALES';
      case GamePhase.reveal:
        return 'REVELANDO MANOS';
      case GamePhase.roundEnd:
        return 'FIN DE RONDA';
      case GamePhase.gameEnd:
        return 'FIN DE PARTIDA';
      case GamePhase.matchEnd:
        return 'FIN DEL MATCH';
      case GamePhase.awaitingLastTurn:
        return game.turnPlayerId == myUid
            ? 'TU ÚLTIMO TURNO'
            : '${_nick(room, game.turnPlayerId).toUpperCase()} JUEGA SU ÚLTIMO TURNO';
      case GamePhase.turn:
      case GamePhase.setup:
        return game.turnPlayerId == myUid
            ? 'TU TURNO'
            : 'TURNO DE ${_nick(room, game.turnPlayerId).toUpperCase()}';
    }
  }

  String _nick(RoomDoc room, String uid) =>
      room.players[uid]?.nickname ?? '???';

  Set<int> _oppHighlights(bool pendingIsMine, PendingAction? p) {
    if (!pendingIsMine) return const {};
    return switch (p) {
      PendingPeekOpponent() ||
      PendingSwap() ||
      PendingKingPeek() =>
        {0, 1, 2, 3},
      _ => const {},
    };
  }

  Set<int> _ownHighlights(bool isMyTurn, PendingAction? p) {
    if (!isMyTurn) return const {};
    if (p == null) return const {};
    return switch (p) {
      PendingPeekOwn() || PendingSwap() || PendingKingPeek() => {0, 1, 2, 3},
      _ => const {},
    };
  }

  ValueChanged<int>? _oppTapHandler(bool pendingIsMine, PendingAction? p) {
    if (!pendingIsMine) return null;
    if (p is PendingPeekOpponent) return onPeekOpp;
    if (p is PendingSwap) return onSelectOpp;
    if (p is PendingKingPeek) {
      if (!p.isComplete) return onPeekOpp;
      return onSelectOpp;
    }
    return null;
  }

  ValueChanged<int>? _ownTapHandler(
    BuildContext context,
    WidgetRef ref,
    bool isMyTurn,
    PendingAction? p,
    GameState game,
  ) {
    // Mirror always needs a selectable own slot (even not your turn).
    if (p == null && game.lastDiscardRank != null) {
      return onSelectOwn;
    }
    if (!isMyTurn) return null;
    if (p == null) {
      // Swap-drawn flow
      if (game.drawnCard != null) return onSelectOwn;
      return onSelectOwn; // allow select for mirror eligibility
    }
    if (p is PendingPeekOwn) return onPeekOwn;
    if (p is PendingSwap) return onSelectOwn;
    if (p is PendingKingPeek) {
      if (!p.isComplete) return onPeekOwn;
      return onSelectOwn;
    }
    return null;
  }

  Widget _buildActionBar(BuildContext context, WidgetRef ref) {
    final isMyTurn = game.turnPlayerId == myUid;
    final pending = game.pending;

    final children = <Widget>[];

    // Swap button when holding a drawn card.
    if (isMyTurn && game.drawnCard != null && pending == null) {
      children.add(OutlinedButton(
        key: const ValueKey('swap'),
        onPressed: selectedOwn == null
            ? null
            : () async {
                final slot = selectedOwn!;
                resetSelection();
                await _runAction(
                    context, () => _ctrl(ref).swap(myUid, slot));
              },
        child: Text(selectedOwn == null ? 'Elegí slot' : 'Swap'),
      ));
    }

    // Cut — only in turn phase, no drawn card, no pending.
    if (isMyTurn &&
        game.drawnCard == null &&
        pending == null &&
        game.phase == GamePhase.turn) {
      children.add(OutlinedButton(
        key: const ValueKey('cut'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.danger,
          side: const BorderSide(color: AppColors.danger),
        ),
        onPressed: () async => _runAction(
            context, () => _ctrl(ref).cut(myUid)),
        child: const Text('Cortar'),
      ));
    }

    // Peek power → just "Listo"
    if (pending is PendingPeekOwn || pending is PendingPeekOpponent) {
      if (isMyTurn) {
        children.add(ElevatedButton(
          key: const ValueKey('ack-peek'),
          onPressed: () async {
            resetSelection();
            await _runAction(
                context, () => _ctrl(ref).acknowledgePeek(myUid));
          },
          child: const Text('Listo'),
        ));
      }
    }

    // Power swap (J/Q)
    if (pending is PendingSwap && isMyTurn) {
      final ready = selectedOwn != null && selectedOpp != null;
      children.add(ElevatedButton(
        key: const ValueKey('power-swap'),
        onPressed: ready
            ? () async {
                final own = selectedOwn!;
                final opp = selectedOpp!;
                resetSelection();
                await _runAction(
                    context,
                    () => _ctrl(ref).powerSwap(myUid,
                        ownSlot: own, opponentSlot: opp));
              }
            : null,
        child: Text(ready ? 'Intercambiar' : 'Elegí 2 cartas'),
      ));
    }

    // King: peek phase — confirm each peeked slot via button
    if (pending is PendingKingPeek && isMyTurn) {
      if (!pending.isComplete) {
        // Need to submit one peek at a time: own or opp.
        final owned = peekOwnReveal.isNotEmpty ? peekOwnReveal.first : null;
        final other = peekOppReveal.isNotEmpty ? peekOppReveal.first : null;
        children.add(ElevatedButton(
          key: const ValueKey('king-peek'),
          onPressed: (owned == null && other == null)
              ? null
              : () async {
                  final isOwn = owned != null;
                  final slot = owned ?? other!;
                  final ownerUid = isOwn ? myUid : game.opponentOf(myUid);
                  resetSelection();
                  await _runAction(
                      context,
                      () => _ctrl(ref).kingPeek(myUid,
                          peekOwnerUid: ownerUid, peekSlot: slot));
                },
          child: Text('Confirmar peek (${pending.peekedSlots.length}/2)'),
        ));
      } else {
        // Decision phase
        final canSwap = selectedOwn != null && selectedOpp != null;
        children.add(OutlinedButton(
          key: const ValueKey('king-decline'),
          onPressed: () async {
            resetSelection();
            await _runAction(
                context, () => _ctrl(ref).kingDecline(myUid));
          },
          child: const Text('No cambiar'),
        ));
        children.add(ElevatedButton(
          key: const ValueKey('king-swap'),
          onPressed: canSwap
              ? () async {
                  final own = selectedOwn!;
                  final opp = selectedOpp!;
                  resetSelection();
                  await _runAction(
                      context,
                      () => _ctrl(ref).kingSwap(myUid,
                          ownSlot: own, opponentSlot: opp));
                }
              : null,
          child: Text(canSwap ? 'Intercambiar' : 'Elegí 2'),
        ));
      }
    }

    if (children.isEmpty) {
      // Filler to keep bar height stable.
      children.add(const SizedBox(
          key: ValueKey('idle'), height: AppSpacing.touchTarget));
    }

    return ActionBar(children: children);
  }

  Future<void> _runAction(
      BuildContext context, Future<void> Function() op) async {
    try {
      await op();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e))),
      );
    }
  }

  String _friendlyError(Object e) {
    final msg = e.toString();
    if (msg.startsWith('GameError')) return msg;
    return 'Error: $msg';
  }
}

class _RevealOverlay extends StatelessWidget {
  const _RevealOverlay({
    required this.onContinue,
    required this.game,
    required this.myUid,
  });

  final VoidCallback onContinue;
  final GameState game;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final oppUid = game.opponentOf(myUid);
    final myScore = game.player(myUid).handScore;
    final oppScore = game.player(oppUid).handScore;
    return _BottomSheet(
      title: 'REVELACIÓN',
      subtitle: 'Tu mano: $myScore · Rival: $oppScore',
      button: 'Continuar',
      onPressed: onContinue,
    );
  }
}

class _RoundEndOverlay extends StatelessWidget {
  const _RoundEndOverlay({
    required this.game,
    required this.myUid,
    required this.isHost,
    required this.onNext,
  });

  final GameState game;
  final String myUid;
  final bool isHost;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final winner = game.roundWinnerUid;
    final subtitle = game.goldenRound
        ? 'Empate: se juega ronda GOLDEN.'
        : (winner == myUid ? 'Ganaste la ronda' : 'Perdiste la ronda');
    return _BottomSheet(
      title: game.goldenRound ? 'GOLDEN ROUND' : 'FIN DE RONDA',
      subtitle: subtitle,
      button: isHost ? 'Siguiente ronda' : 'Esperando anfitrión...',
      onPressed: isHost ? onNext : null,
    );
  }
}

class _GameEndOverlay extends StatelessWidget {
  const _GameEndOverlay({
    required this.game,
    required this.myUid,
    required this.isHost,
    required this.onNext,
  });

  final GameState game;
  final String myUid;
  final bool isHost;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final mine = game.gamesWon[myUid] ?? 0;
    final theirs = game.gamesWon[game.opponentOf(myUid)] ?? 0;
    return _BottomSheet(
      title: 'FIN DE PARTIDA',
      subtitle: 'Partidas ganadas: $mine–$theirs',
      button: isHost ? 'Siguiente partida' : 'Esperando anfitrión...',
      onPressed: isHost ? onNext : null,
    );
  }
}

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    required this.title,
    required this.subtitle,
    required this.button,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String button;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.base),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppText.headline, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text(subtitle, style: AppText.body, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: onPressed,
              child: Text(button),
            ),
          ],
        ),
      ),
    );
  }
}
