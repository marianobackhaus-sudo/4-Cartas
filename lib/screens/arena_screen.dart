import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../data/room_doc.dart';
import '../engine/models/card.dart';
import '../engine/models/game_phase.dart';
import '../engine/models/game_state.dart';
import '../engine/models/pending_action.dart';
import '../state/auth_providers.dart';
import '../state/game_controller.dart';
import '../state/room_providers.dart';

// ─── Phase ────────────────────────────────────────────────────────────────────

enum _Phase {
  peekInitial,             // Start: choose 2 cards to memorize
  turn,                    // Normal turn: tap mazo or cut
  cardDrawn,               // Card drawn, waiting for action
  powerPeekOwn,            // 7/8: peek one own card
  powerPeekOpponent,       // 9/10: peek one opponent card
  powerSwapSelectOwn,      // J/Q step 1: select own card
  powerSwapSelectOpponent, // J/Q step 2: select opponent card
  powerKingPeek,           // K step 1: peek any 2 cards
  powerKingDecide,         // K step 2: swap or leave
}

// ─── King Target ──────────────────────────────────────────────────────────────

class _KingTarget {
  final bool isOwn;
  final int slot;
  const _KingTarget(this.isOwn, this.slot);

  @override
  bool operator ==(Object o) => o is _KingTarget && o.isOwn == isOwn && o.slot == slot;
  @override
  int get hashCode => Object.hash(isOwn, slot);
}

// ─── Discard Entry ────────────────────────────────────────────────────────────

class _DiscardEntry {
  final GameCard card;
  final double angle;
  final Offset offset;
  const _DiscardEntry(this.card, this.angle, this.offset);
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _suitSymbol(Suit s) {
  switch (s) {
    case Suit.hearts:   return '♥';
    case Suit.diamonds: return '♦';
    case Suit.clubs:    return '♣';
    case Suit.spades:   return '♠';
  }
}

String _rankLabel(int r) {
  switch (r) {
    case 1: return 'A';  case 11: return 'J';
    case 12: return 'Q'; case 13: return 'K';
    default: return '$r';
  }
}

Color _suitColor(Suit s) =>
    (s == Suit.hearts || s == Suit.diamonds)
        ? AppColors.cardInkRed
        : AppColors.cardInkBlack;

// ─── Card Face ────────────────────────────────────────────────────────────────

class _CardFace extends StatelessWidget {
  final GameCard card;
  final double width;
  const _CardFace({required this.card, this.width = 72});

  @override
  Widget build(BuildContext context) {
    if (card.isJoker) return _JokerFace(width: width);
    final color = _suitColor(card.suit!);
    final sym = _suitSymbol(card.suit!);
    final rnk = _rankLabel(card.rank);
    final h = width / AppCardDims.aspectRatio;

    return Container(
      width: width, height: h,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardFaceEdge),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Stack(children: [
        Positioned(top: 5, left: 7, child: _CornerLabel(rnk: rnk, sym: sym, color: color)),
        Center(child: Text(sym, style: TextStyle(color: color, fontSize: width * .30, height: 1, fontWeight: FontWeight.w700))),
        Positioned(bottom: 5, right: 7, child: Transform.rotate(angle: math.pi, child: _CornerLabel(rnk: rnk, sym: sym, color: color))),
      ]),
    );
  }
}

class _JokerFace extends StatelessWidget {
  final double width;
  const _JokerFace({this.width = 72});
  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    return Container(
      width: width, height: h,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardInkJoker.withValues(alpha: .6)),
        boxShadow: [const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          BoxShadow(color: AppColors.cardInkJoker.withValues(alpha: .3), blurRadius: 12)],
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('★', style: TextStyle(color: AppColors.cardInkJoker, fontSize: width * .28, height: 1)),
        Text('JKR', style: TextStyle(color: AppColors.cardInkJoker, fontSize: width * .14, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ])),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  final String rnk, sym;
  final Color color;
  const _CornerLabel({required this.rnk, required this.sym, required this.color});
  @override
  Widget build(BuildContext context) {
    final s = TextStyle(color: color, fontWeight: FontWeight.w800, height: 1.1, fontSize: 13);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(rnk, style: s), Text(sym, style: s.copyWith(fontSize: 11))]);
  }
}

// ─── Card Back ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final double width;
  final Color? borderColor;
  final bool eyeActive;
  final Color eyeColor;
  final bool selected; // J/Q swap selected

  final Color patternColor;

  const _CardBack({
    this.width = 72, this.borderColor, this.eyeActive = false,
    this.eyeColor = AppColors.accent, this.selected = false,
    this.patternColor = AppColors.cardBackPattern,
  });

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    final bc = selected
        ? AppColors.primary
        : borderColor ?? (eyeActive ? eyeColor : AppColors.border);
    final bw = (eyeActive || selected) ? 1.5 : 1.0;

    return Container(
      width: width, height: h,
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withValues(alpha: .12)
            : AppColors.cardBack,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: bc, width: bw),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          if (eyeActive || selected)
            BoxShadow(color: bc.withValues(alpha: .40), blurRadius: 16, spreadRadius: 2),
        ],
      ),
      child: eyeActive
          ? Center(child: Icon(Icons.visibility_outlined, color: eyeColor, size: width * .46))
          : selected
              ? Center(child: Icon(Icons.swap_horiz_rounded, color: AppColors.primary, size: width * .46))
              : Padding(
                  padding: EdgeInsets.all(width * 0.09),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                      border: Border.all(
                        color: patternColor.withValues(alpha: 0.40),
                        width: 1.0,
                      ),
                    ),
                    child: Center(
                      child: Text('♦',
                        style: TextStyle(
                          color: patternColor.withValues(alpha: 0.45),
                          fontSize: width * 0.22,
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }
}

// ─── Flip Card ────────────────────────────────────────────────────────────────

class _FlippableCard extends StatefulWidget {
  final bool showFace;
  final Widget front;
  final Widget back;
  const _FlippableCard({super.key, required this.showFace, required this.front, required this.back});

  @override
  State<_FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<_FlippableCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _anim = Tween<double>(begin: 0.0, end: math.pi).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.showFace) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_FlippableCard old) {
    super.didUpdateWidget(old);
    if (widget.showFace != old.showFace) widget.showFace ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, ch) {
        final angle = _anim.value;
        final showFront = angle > math.pi / 2;
        return Transform(
          transform: Matrix4.identity()..setEntry(3, 2, 0.001)..rotateY(showFront ? angle - math.pi : angle),
          alignment: Alignment.center,
          child: showFront ? widget.front : widget.back,
        );
      },
    );
  }
}

// ─── Deck Card ────────────────────────────────────────────────────────────────

class _DeckCard extends StatelessWidget {
  final double width;
  final int count;
  final VoidCallback? onTap;
  final bool canDraw;
  const _DeckCard({this.width = 100, required this.count, this.onTap, this.canDraw = true});

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    return GestureDetector(
      onTap: canDraw ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width, height: h,
        decoration: BoxDecoration(
          color: AppColors.cardBack,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: canDraw ? AppColors.primary.withValues(alpha: .7) : AppColors.border,
            width: canDraw ? 1.5 : 1.0),
          boxShadow: [
            const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            if (canDraw) BoxShadow(color: AppColors.primary.withValues(alpha: .25), blurRadius: 14),
          ],
        ),
        child: Center(child: _StackedCardsIcon(size: width * .52)),
      ),
    );
  }
}

class _StackedCardsIcon extends StatelessWidget {
  final double size;
  const _StackedCardsIcon({required this.size});

  Widget _mini(double angle, double opacity) => Transform.rotate(
    angle: angle,
    child: Container(
      width: size, height: size / AppCardDims.aspectRatio,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: opacity * .18),
        borderRadius: BorderRadius.circular(size * .12),
        border: Border.all(color: AppColors.primary.withValues(alpha: opacity), width: 1),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size * 1.5, height: (size / AppCardDims.aspectRatio) * 1.35,
    child: Stack(alignment: Alignment.center, children: [
      _mini(-0.28, 0.35), _mini(0.18, 0.55), _mini(0.0, 0.90),
    ]),
  );
}

// ─── Discard Pile ─────────────────────────────────────────────────────────────

class _DiscardPile extends StatelessWidget {
  final List<_DiscardEntry> stack;
  final double width;
  const _DiscardPile({required this.stack, this.width = 100});

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    if (stack.isEmpty) {
      return Container(
        width: width, height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border)),
        child: Center(child: Text('DESCARTE', style: AppText.caption)),
      );
    }
    final visible = stack.length > 10 ? stack.sublist(stack.length - 10) : stack;
    return SizedBox(
      width: width + 28, height: h + 28,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: visible.map((e) => Transform.translate(
          offset: e.offset,
          child: Transform.rotate(angle: e.angle, child: _CardFace(card: e.card, width: width)),
        )).toList(),
      ),
    );
  }
}

// ─── Power Banner ─────────────────────────────────────────────────────────────

class _PowerBannerOverlay extends StatelessWidget {
  final bool visible;
  final String text;
  final String sub;
  final Color color;
  const _PowerBannerOverlay({required this.visible, required this.text, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 350),
        child: Container(
          color: Colors.black.withValues(alpha: .45),
          child: Center(
            child: AnimatedScale(
              scale: visible ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 350),
              curve: Curves.elasticOut,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.bgDeepest,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: color, width: 2),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: .45), blurRadius: 30, spreadRadius: 4)],
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(text, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(sub, style: AppText.caption.copyWith(color: color.withValues(alpha: .8))),
                  ],
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Arena Screen ─────────────────────────────────────────────────────────────

class ArenaScreen extends ConsumerStatefulWidget {
  const ArenaScreen({super.key, required this.roomCode});
  final String roomCode;

  @override
  ConsumerState<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends ConsumerState<ArenaScreen> {
  // ── UI-only state (NOT in GameState; resets per player/phase) ──────────────
  final Set<int> _initialPeekShowing = {};
  Timer? _peekHideTimer;

  int? _revealOwnSlot;
  int? _revealOpponentSlot;
  Timer? _revealTimer;

  final Set<int> _justSwappedSlots = {};
  int? _swapOwnSlot;

  // Banner overlay
  bool _bannerVisible = false;
  String _bannerText = '';
  String _bannerSub = '';
  Color _bannerColor = AppColors.primary;

  // Transition detection
  String? _prevPendingKey;
  GamePhase? _prevPhase;
  String? _prevCutterId;

  // Settings
  double _musicVolume = 0.8;
  double _fxVolume = 1.0;
  bool _hapticEnabled = true;

  @override
  void dispose() {
    _peekHideTimer?.cancel();
    _revealTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  GameController _ctrl() =>
      ref.read(gameControllerProvider(widget.roomCode));

  String _pendingKey(PendingAction? p) {
    if (p == null) return '';
    return switch (p) {
      PendingPeekOwn() => 'peekOwn-${p.rank}',
      PendingPeekOpponent() => 'peekOpp-${p.rank}',
      PendingSwap() => 'swap-${p.rank}',
      PendingKingPeek() => 'king-${p.peekedSlots.length}',
    };
  }

  _Phase _derivePhase(GameState g, String myUid) {
    if (g.phase == GamePhase.peekInitial) return _Phase.peekInitial;
    if (g.turnPlayerId != myUid) return _Phase.turn;
    final pending = g.pending;
    if (pending is PendingPeekOwn) return _Phase.powerPeekOwn;
    if (pending is PendingPeekOpponent) return _Phase.powerPeekOpponent;
    if (pending is PendingSwap) {
      return _swapOwnSlot == null
          ? _Phase.powerSwapSelectOwn
          : _Phase.powerSwapSelectOpponent;
    }
    if (pending is PendingKingPeek) {
      return pending.isComplete
          ? _Phase.powerKingDecide
          : _Phase.powerKingPeek;
    }
    if (g.drawnCard != null) return _Phase.cardDrawn;
    return _Phase.turn;
  }

  List<_DiscardEntry> _discardEntries(List<GameCard> discard) {
    return [
      for (var i = 0; i < discard.length; i++)
        _DiscardEntry(
          discard[i],
          _stableAngle(i, discard[i]),
          _stableOffset(i, discard[i]),
        ),
    ];
  }

  double _stableAngle(int i, GameCard c) {
    final seed = (i * 31 + c.hashCode) & 0xFFFF;
    return ((seed / 0xFFFF) - 0.5) * 0.52;
  }

  Offset _stableOffset(int i, GameCard c) {
    final sx = ((i * 37 + c.hashCode) & 0xFFFF) / 0xFFFF;
    final sy = (((i * 53 + c.hashCode) ^ 0x1234) & 0xFFFF) / 0xFFFF;
    return Offset((sx - 0.5) * 14, (sy - 0.5) * 10);
  }

  void _showBanner(
    String text,
    String sub,
    Color color, {
    Duration dur = const Duration(milliseconds: 1600),
  }) {
    if (!mounted) return;
    setState(() {
      _bannerVisible = true;
      _bannerText = text;
      _bannerSub = sub;
      _bannerColor = color;
    });
    Future.delayed(dur, () {
      if (mounted) setState(() => _bannerVisible = false);
    });
  }

  /// Returns true if the op succeeded, false if it threw.
  Future<bool> _runAction(Future<void> Function() op) async {
    try {
      await op();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
      return false;
    }
  }

  void _onStateChange(
      GameState? prev, GameState next, String myUid, bool isHost) {
    final prevPending = _prevPendingKey;
    final nextPending = _pendingKey(next.pending);
    final prevPhase = _prevPhase;

    if (prevPending != nextPending &&
        next.pending != null &&
        next.turnPlayerId == myUid) {
      _announcePower(next.pending!);
    }

    if (_prevCutterId == null && next.cutterId != null) {
      final cutter =
          next.cutterId == myUid ? 'Vos cortaste' : 'Cortó el rival';
      _showBanner('¡CORTE!', cutter, AppColors.danger,
          dur: const Duration(seconds: 2));
    }

    if (isHost && next.phase != prevPhase) {
      if (next.phase == GamePhase.reveal) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (!mounted) return;
          _runAction(() => _ctrl().advanceReveal());
        });
      } else if (next.phase == GamePhase.roundEnd) {
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (!mounted) return;
          _runAction(() => _ctrl().nextRound());
        });
      }
    }

    _prevPendingKey = nextPending;
    _prevPhase = next.phase;
    _prevCutterId = next.cutterId;
  }

  void _announcePower(PendingAction p) {
    switch (p) {
      case PendingPeekOwn():
        _showBanner(
            'PODER ${_rankLabel(p.rank)}', 'Mirá una carta tuya', AppColors.accent);
      case PendingPeekOpponent():
        _showBanner('PODER ${_rankLabel(p.rank)}', 'Mirá una carta del rival',
            AppColors.warning);
      case PendingSwap():
        _showBanner('PODER ${_rankLabel(p.rank)}',
            'Intercambiá una tuya con una del rival', AppColors.success);
      case PendingKingPeek():
        if (!p.isComplete) {
          _showBanner(
              'PODER REY',
              'Mirá 1 tuya y 1 del rival, decidí si intercambiar',
              AppColors.primary);
        }
    }
  }

  // ── Initial peek ───────────────────────────────────────────────────────────

  void _onTapInitialPeek(int i, String myUid) {
    if (_initialPeekShowing.contains(i)) return;
    if (_initialPeekShowing.length >= 2) return;

    _peekHideTimer?.cancel();
    setState(() => _initialPeekShowing.add(i));

    if (_initialPeekShowing.length == 2) {
      _peekHideTimer = Timer(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _initialPeekShowing.clear());
        _runAction(() => _ctrl().completeInitialPeek(myUid));
      });
    }
  }

  // ── Turn actions ───────────────────────────────────────────────────────────

  void _drawCard(String myUid) =>
      _runAction(() => _ctrl().drawFromDeck(myUid));

  void _discardDrawn(String myUid) =>
      _runAction(() => _ctrl().discardDrawn(myUid));

  Future<void> _swapWithSlot(int i, String myUid) async {
    setState(() => _justSwappedSlots.add(i));
    await _runAction(() => _ctrl().swap(myUid, i));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _justSwappedSlots.remove(i));
    });
  }

  void _handleCut(String myUid) => _runAction(() => _ctrl().cut(myUid));

  // ── Powers ─────────────────────────────────────────────────────────────────

  void _onPeekOwn(int i, String myUid) {
    _revealTimer?.cancel();
    setState(() => _revealOwnSlot = i);
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _revealOwnSlot = null);
      _runAction(() => _ctrl().acknowledgePeek(myUid));
    });
  }

  void _onPeekOpponent(int i, String myUid) {
    _revealTimer?.cancel();
    setState(() => _revealOpponentSlot = i);
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _revealOpponentSlot = null);
      _runAction(() => _ctrl().acknowledgePeek(myUid));
    });
  }

  void _onSwapSelectOwn(int i) => setState(() => _swapOwnSlot = i);

  Future<void> _onSwapSelectOpponent(int i, String myUid) async {
    final own = _swapOwnSlot;
    if (own == null) return;
    setState(() {
      _swapOwnSlot = null;
      _justSwappedSlots.add(own);
    });
    await _runAction(() =>
        _ctrl().powerSwap(myUid, ownSlot: own, opponentSlot: i));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _justSwappedSlots.remove(own));
    });
    _showBanner('¡INTERCAMBIO!', '', AppColors.success);
  }

  void _onKingPeek(bool isOwn, int i, String myUid, String oppUid) {
    final ownerUid = isOwn ? myUid : oppUid;
    _runAction(
        () => _ctrl().kingPeek(myUid, peekOwnerUid: ownerUid, peekSlot: i));
  }

  void _kingDecide(bool doSwap, GameState g, String myUid) {
    final pending = g.pending;
    if (pending is! PendingKingPeek || !pending.isComplete) return;
    if (!doSwap) {
      _runAction(() => _ctrl().kingDecline(myUid));
      return;
    }
    int? ownSlot;
    int? oppSlot;
    for (var k = 0; k < pending.peekedOwnerUids.length; k++) {
      if (pending.peekedOwnerUids[k] == myUid) {
        ownSlot = pending.peekedSlots[k];
      } else {
        oppSlot = pending.peekedSlots[k];
      }
    }
    if (ownSlot == null || oppSlot == null) return;
    final ownSlotFinal = ownSlot;
    final oppSlotFinal = oppSlot;
    _runAction(() => _ctrl()
        .kingSwap(myUid, ownSlot: ownSlotFinal, opponentSlot: oppSlotFinal));
    _showBanner('¡INTERCAMBIO REY!', '', AppColors.primary);
  }

  // ── Mirror ─────────────────────────────────────────────────────────────────

  /// Mirror: engine finds all matching cards and removes them. The player just
  /// taps ESPEJO — no slot selection needed.
  Future<void> _handleMirror(GameState g, String myUid) async {
    final mySlots = g.player(myUid).slots;
    if (mySlots.isEmpty) return;

    // Preemptive guards: give user feedback instead of silently doing nothing.
    if (g.pending != null) {
      _showBanner('ESPEJO BLOQUEADO',
          'Esperá a que se resuelva el poder', AppColors.warning);
      return;
    }
    if (g.phase != GamePhase.turn &&
        g.phase != GamePhase.awaitingLastTurn) {
      _showBanner('ESPEJO NO DISPONIBLE',
          'No se puede ahora (${g.phase.name})', AppColors.warning);
      return;
    }

    final lastRank = g.lastDiscardRank;
    final topIsJoker = lastRank == null &&
        g.discard.isNotEmpty &&
        g.discard.last.isJoker;
    if (lastRank == null && !topIsJoker) {
      _showBanner('ESPEJO NO DISPONIBLE',
          'No hay carta en el descarte', AppColors.warning);
      return;
    }

    // Determine locally whether a match exists (for banner only; engine is authoritative).
    bool hasMatch;
    if (topIsJoker) {
      hasMatch = mySlots.any((s) => s.card.isJoker);
    } else {
      hasMatch = mySlots.any((s) => !s.card.isJoker && s.card.rank == lastRank);
    }

    // slotIndex is ignored by the engine — pass 0 as a placeholder.
    final ok = await _runAction(() => _ctrl().mirrorAttempt(myUid, 0));
    if (!ok) return;
    if (hasMatch) {
      _showBanner('¡ESPEJO!', 'Carta al descarte', AppColors.success);
    } else {
      _showBanner('¡FALLASTE!', '+5 puntos de penalidad', AppColors.danger);
    }
  }

  // ── Exit / Settings dialogs ────────────────────────────────────────────────

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl)),
        title: const Text('¿Salir del juego?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        content: const Text('Perderás el progreso de la partida actual.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/');
            },
            child: const Text('Salir',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final sliderTheme = SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withValues(alpha: .18),
            trackHeight: 3,
          );
          return Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.base,
                AppSpacing.xl, AppSpacing.xl2),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(AppRadius.pill))),
              const SizedBox(height: AppSpacing.xl),
              const Text('CONFIGURACIÓN',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2)),
              const SizedBox(height: AppSpacing.xl2),
              Row(children: [
                const Icon(Icons.music_note_rounded,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text('Música',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(_musicVolume * 100).round()}%',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ]),
              SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: _musicVolume,
                  onChanged: (v) {
                    setState(() => _musicVolume = v);
                    setSheet(() {});
                  },
                ),
              ),
              Row(children: [
                const Icon(Icons.volume_up_rounded,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text('Sonido FX',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Text('${(_fxVolume * 100).round()}%',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 12)),
              ]),
              SliderTheme(
                data: sliderTheme,
                child: Slider(
                  value: _fxVolume,
                  onChanged: (v) {
                    setState(() => _fxVolume = v);
                    setSheet(() {});
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(children: [
                const Icon(Icons.vibration_rounded,
                    color: AppColors.textSecondary, size: 20),
                const SizedBox(width: AppSpacing.sm),
                const Text('Vibración',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500)),
                const Spacer(),
                Switch(
                  value: _hapticEnabled,
                  onChanged: (v) {
                    setState(() => _hapticEnabled = v);
                    setSheet(() {});
                  },
                  activeThumbColor: AppColors.primary,
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                ),
              ]),
            ]),
          );
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    ref.listen(roomStreamProvider(widget.roomCode), (prev, next) {
      final prevGame = prev?.asData?.value?.game;
      final nextGame = next.asData?.value?.game;
      if (nextGame == null) return;
      final room = next.asData?.value;
      final myUid = ref.read(currentUserIdProvider).asData?.value;
      if (room == null || myUid == null) return;
      final isHost = room.hostId == myUid;
      _onStateChange(prevGame, nextGame, myUid, isHost);
    });

    final roomAsync = ref.watch(roomStreamProvider(widget.roomCode));
    final uidAsync = ref.watch(currentUserIdProvider);

    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout_rounded,
              color: AppColors.textSecondary),
          onPressed: () => _confirmExit(context),
        ),
        title: const Text('4 CARTAS BLITZ',
            style: TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.5)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.textSecondary),
            onPressed: () => _openSettings(context),
          ),
        ],
      ),
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: AppText.body.copyWith(color: AppColors.danger))),
        data: (room) {
          if (room == null) {
            return const Center(
                child: Text('Sala no encontrada', style: AppText.title));
          }
          final game = room.game;
          final myUid = uidAsync.asData?.value;
          if (game == null || myUid == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _buildBody(context, room, game, myUid);
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, RoomDoc room, GameState game, String myUid) {
    final oppUid = game.opponentOf(myUid);
    final myHandSlots = game.player(myUid).slots;
    final oppHandSlots = game.player(oppUid).slots;
    final myCards = myHandSlots.map((s) => s.card).toList();
    final oppCards = oppHandSlots.map((s) => s.card).toList();

    final phase = _derivePhase(game, myUid);
    final isOpponentTurn = game.turnPlayerId != myUid;

    final pending = game.pending;
    final kingTargets = pending is PendingKingPeek
        ? [
            for (var k = 0; k < pending.peekedSlots.length; k++)
              _KingTarget(pending.peekedOwnerUids[k] == myUid,
                  pending.peekedSlots[k]),
          ]
        : <_KingTarget>[];

    final hasOwnKingTarget = kingTargets.any((t) => t.isOwn);
    final hasOppKingTarget = kingTargets.any((t) => !t.isOwn);
    final opponentEye = phase == _Phase.powerPeekOpponent;
    final opponentKingEye =
        phase == _Phase.powerKingPeek && !hasOppKingTarget;
    final ownKingEyeEnabled =
        phase == _Phase.powerKingPeek && !hasOwnKingTarget;
    final opponentKingPeeked =
        kingTargets.where((t) => !t.isOwn).map((t) => t.slot).toSet();
    final playerKingPeeked =
        kingTargets.where((t) => t.isOwn).map((t) => t.slot).toSet();
    final swapOpponent = phase == _Phase.powerSwapSelectOpponent;

    final roundsRemaining = game.totalRounds - game.roundIndex;
    final myWins = game.gamesWon[myUid] ?? 0;
    final oppWins = game.gamesWon[oppUid] ?? 0;
    final currentPartida = game.gameIndex + 1;
    final partidaOver =
        game.phase == GamePhase.gameEnd || game.phase == GamePhase.matchEnd;
    final matchOver = game.phase == GamePhase.matchEnd;
    final isHost = room.hostId == myUid;
    // Accumulated totals from the engine (penalty already included in roundPoints).
    final myTotalScore = game.roundPoints[myUid] ?? 0;
    final oppTotalScore = game.roundPoints[oppUid] ?? 0;

    return Stack(children: [
      Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.bgBase, AppColors.bgDeepest])),
        child: SafeArea(
          child: Column(children: [
            _OpponentSection(
              opponentCards: oppCards,
              revealingSlot: _revealOpponentSlot,
              peekEye: opponentEye || opponentKingEye,
              kingPeekedSlots: opponentKingPeeked,
              swapSelectable: swapOpponent,
              isThinking: isOpponentTurn,
              onTapCard: (i) {
                if (phase == _Phase.powerPeekOpponent) {
                  _onPeekOpponent(i, myUid);
                } else if (opponentKingEye) {
                  _onKingPeek(false, i, myUid, oppUid);
                } else if (phase == _Phase.powerSwapSelectOpponent) {
                  _onSwapSelectOpponent(i, myUid);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _RoundsBadge(
              remaining: roundsRemaining,
              currentPartida: currentPartida,
              playerWins: myWins,
              opponentWins: oppWins,
            ),
            const SizedBox(height: AppSpacing.xs),
            _PhaseHint(
              phase: phase,
              peeksUsed: _initialPeekShowing.length,
              kingCount: kingTargets.length,
              swapOwnSelected: _swapOwnSlot != null,
              kingPickedOwn: hasOwnKingTarget,
              kingPickedOpp: hasOppKingTarget,
            ),
            const Spacer(),
            _TurnIndicator(
                isPlayerTurn: !isOpponentTurn && pending == null),
            const SizedBox(height: AppSpacing.sm),
            _TableCenter(
              deckCount: game.deck.length,
              discardStack: _discardEntries(game.discard),
              drawnCard: game.drawnCard,
              canDraw: !isOpponentTurn &&
                  game.drawnCard == null &&
                  pending == null &&
                  (game.phase == GamePhase.turn ||
                      game.phase == GamePhase.awaitingLastTurn),
              onDrawCard: () => _drawCard(myUid),
              onDiscardDrawn: () => _discardDrawn(myUid),
            ),
            const Spacer(),
            _ActionBar(
              phase: phase,
              isOpponentTurn: isOpponentTurn,
              cutPending: game.cutPending,
              onCut: () => _handleCut(myUid),
              onMirror: () => _handleMirror(game, myUid),
              onKingSwap: () => _kingDecide(true, game, myUid),
              onKingKeep: () => _kingDecide(false, game, myUid),
            ),
            const SizedBox(height: AppSpacing.xs),
            _PlayerHand(
              playerCards: myCards,
              phase: phase,
              revealingSlot: _revealOwnSlot,
              kingPeekedSlots: playerKingPeeked,
              justSwappedSlots: _justSwappedSlots,
              initialPeekShowing: _initialPeekShowing,
              swapOwnSlot: _swapOwnSlot,
              ownKingEyeEnabled: ownKingEyeEnabled,
              onTapCard: (i) {
                if (phase == _Phase.peekInitial) {
                  _onTapInitialPeek(i, myUid);
                } else if (phase == _Phase.cardDrawn) {
                  _swapWithSlot(i, myUid);
                } else if (phase == _Phase.powerPeekOwn) {
                  _onPeekOwn(i, myUid);
                } else if (ownKingEyeEnabled) {
                  _onKingPeek(true, i, myUid, oppUid);
                } else if (phase == _Phase.powerSwapSelectOwn) {
                  _onSwapSelectOwn(i);
                }
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ]),
        ),
      ),
      Positioned.fill(
        child: _PowerBannerOverlay(
          visible: _bannerVisible,
          text: _bannerText,
          sub: _bannerSub,
          color: _bannerColor,
        ),
      ),
      if (partidaOver)
        Positioned.fill(
          child: _GameOverOverlay(
            playerCards: myCards,
            playerTotalScore: myTotalScore,
            opponentTotalScore: oppTotalScore,
            playerPartidaWins: myWins,
            opponentPartidaWins: oppWins,
            currentPartida: currentPartida,
            matchOver: matchOver,
            onNextPartida: isHost
                ? () => _runAction(() => _ctrl().nextGame())
                : () {},
            onNewMatch: () => context.go('/'),
            onExit: () => context.go('/'),
          ),
        ),
    ]);
  }
}

// ─── Coin Stack Icon ─────────────────────────────────────────────────────────

class _CoinStackIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _CoinStackIcon({this.size = 28, this.color = AppColors.primary});

  Widget _coin(double w, double h, double alpha) => Container(
    width: w, height: h,
    decoration: BoxDecoration(
      color: color.withValues(alpha: alpha * .85),
      borderRadius: BorderRadius.circular(h / 2),
      border: Border.all(color: color, width: 1.2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final w = size * 1.15;
    final h = size * 0.32;
    final gap = h * 0.72;
    return SizedBox(
      width: w,
      height: h + gap * 2,
      child: Stack(alignment: Alignment.bottomCenter, children: [
        Positioned(bottom: 0,       child: _coin(w, h, 1.0)),
        Positioned(bottom: gap,     child: _coin(w, h, 0.80)),
        Positioned(bottom: gap * 2, child: _coin(w, h, 0.60)),
      ]),
    );
  }
}

// ─── Game Over Overlay ────────────────────────────────────────────────────────

class _GameOverOverlay extends StatelessWidget {
  final List<GameCard> playerCards;
  final int playerTotalScore;
  final int opponentTotalScore;
  final int playerPartidaWins;
  final int opponentPartidaWins;
  final int currentPartida;
  final bool matchOver;
  final VoidCallback onNextPartida;
  final VoidCallback onNewMatch;
  final VoidCallback onExit;

  const _GameOverOverlay({
    required this.playerCards,
    required this.playerTotalScore,
    required this.opponentTotalScore,
    required this.playerPartidaWins,
    required this.opponentPartidaWins,
    required this.currentPartida,
    required this.matchOver,
    required this.onNextPartida,
    required this.onNewMatch,
    required this.onExit,
  });

  Widget _cardCol(GameCard card) {
    final valLabel = card.isJoker ? '−2' : '${card.value}';
    final valColor = card.isJoker ? AppColors.cardInkJoker : AppColors.textPrimary;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _CardFace(card: card, width: 58),
      const SizedBox(height: 5),
      Text(valLabel, style: TextStyle(color: valColor, fontSize: 13, fontWeight: FontWeight.w700)),
    ]);
  }

  Widget _winDot(bool filled) => Container(
    width: 10, height: 10,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? AppColors.primary : Colors.transparent,
      border: Border.all(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final playerScore = playerTotalScore;
    final opponentScore = opponentTotalScore;
    final playerWinsPartida = playerScore < opponentScore;
    final tied = playerScore == opponentScore;

    final String resultLabel;
    final Color resultColor;
    if (tied) {
      resultLabel = 'EMPATE en esta partida';
      resultColor = AppColors.warning;
    } else if (playerWinsPartida) {
      resultLabel = matchOver
          ? (playerPartidaWins >= 2 ? '¡GANASTE EL MATCH!' : '¡Ganaste esta partida!')
          : '¡Ganaste esta partida!';
      resultColor = AppColors.success;
    } else {
      resultLabel = matchOver
          ? (opponentPartidaWins >= 2 ? 'El rival ganó el match' : 'El rival ganó esta partida')
          : 'El rival ganó esta partida';
      resultColor = AppColors.danger;
    }

    final String actionLabel = matchOver ? 'NUEVA PARTIDA' : 'SEGUIR';
    final VoidCallback actionTap = matchOver ? onNewMatch : onNextPartida;
    final Color frameColor = tied
        ? AppColors.warning
        : playerWinsPartida ? AppColors.success : AppColors.danger;

    return Container(
      color: Colors.black.withValues(alpha: .90),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.base),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: frameColor, width: 2),
              boxShadow: [BoxShadow(color: frameColor.withValues(alpha: .35), blurRadius: 32, spreadRadius: 2)],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Header: partida + dots + result
              const SizedBox(height: AppSpacing.xs),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('PARTIDA $currentPartida/3  ', style: AppText.caption.copyWith(letterSpacing: 1)),
                Row(children: List.generate(2, (i) => _winDot(i < playerPartidaWins))),
                Text('  vs  ', style: AppText.caption),
                Row(children: List.generate(2, (i) => _winDot(i < opponentPartidaWins))),
              ]),
              const SizedBox(height: AppSpacing.xs),
              Text(resultLabel, style: TextStyle(
                  color: resultColor, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
              const SizedBox(height: AppSpacing.base),

              // Player cards (compact)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: playerCards
                      .map((c) => Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: _cardCol(c)))
                      .toList(),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Score comparison — single line
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('TÚ  ', style: AppText.caption),
                  Text('$playerScore', style: TextStyle(
                      color: AppColors.primary, fontSize: 28, fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
                    child: Text('vs', style: AppText.caption),
                  ),
                  Text('$opponentScore', style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 28, fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()])),
                  Text('  RIVAL', style: AppText.caption),
                ]),
              ),

              if (matchOver) ...[
                const SizedBox(height: AppSpacing.sm),
                // Coins
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      AppColors.primary.withValues(alpha: .18),
                      AppColors.warning.withValues(alpha: .10),
                    ]),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(color: AppColors.primary.withValues(alpha: .5)),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _CoinStackIcon(size: 26, color: AppColors.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text('+${playerWinsPartida || tied ? 100 : 25}', style: const TextStyle(
                        color: AppColors.primary, fontSize: 26, fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()])),
                    const SizedBox(width: AppSpacing.xs),
                    Text('monedas', style: AppText.label.copyWith(color: AppColors.primary)),
                  ]),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Watch video
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: double.infinity, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.warning, width: 1.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.play_circle_outline_rounded, color: AppColors.warning, size: 18),
                      const SizedBox(width: AppSpacing.xs),
                      Text('VER VIDEO Y DUPLICAR', style: TextStyle(
                          color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.sm),
              // Buttons
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: onExit,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border, width: 1.5),
                    ),
                    child: const Center(child: Text('SALIR', style: TextStyle(
                        color: AppColors.textSecondary, fontWeight: FontWeight.w800, letterSpacing: 1))),
                  ),
                )),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: GestureDetector(
                  onTap: actionTap,
                  child: Container(
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .4), blurRadius: 10)],
                    ),
                    child: Center(child: Text(actionLabel,
                        style: const TextStyle(color: AppColors.bgDeepest,
                            fontWeight: FontWeight.w800, fontSize: 13))),
                  ),
                )),
              ]),
              const SizedBox(height: AppSpacing.xs),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Opponent Section ─────────────────────────────────────────────────────────

class _OpponentSection extends StatelessWidget {
  final List<GameCard> opponentCards;
  final int? revealingSlot;
  final bool peekEye;
  final Set<int> kingPeekedSlots;
  final bool swapSelectable;
  final bool isThinking;
  final void Function(int) onTapCard;

  const _OpponentSection({
    required this.opponentCards, required this.revealingSlot,
    required this.peekEye, required this.kingPeekedSlots,
    required this.swapSelectable, required this.isThinking, required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: AppColors.border)),
              child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NEON_DRIFTER', style: AppText.titleSmall),
              const SizedBox(height: 3),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isThinking
                  ? Row(key: const ValueKey('thinking'), children: [
                      Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Pensando...', style: AppText.caption.copyWith(
                          color: AppColors.success, fontWeight: FontWeight.w500)),
                    ])
                  : Row(key: const ValueKey('waiting'), children: [
                      Container(width: 7, height: 7,
                          decoration: const BoxDecoration(color: AppColors.textMuted, shape: BoxShape.circle)),
                      const SizedBox(width: 5),
                      Text('Esperando', style: AppText.caption.copyWith(
                          color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                    ]),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(opponentCards.length, (i) {
            final isRevealing = revealingSlot == i;
            final isKingPeeked = kingPeekedSlots.contains(i);
            final showFace = isRevealing || isKingPeeked;
            final tappable = peekEye && !showFace || swapSelectable;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
              child: GestureDetector(
                onTap: tappable ? () => onTapCard(i) : null,
                child: _FlippableCard(
                  showFace: showFace,
                  front: _CardFace(card: opponentCards[i], width: 68),
                  back: _CardBack(
                    width: 68,
                    eyeActive: peekEye && !isKingPeeked,
                    eyeColor: AppColors.warning,
                    selected: swapSelectable,
                    patternColor: AppColors.cardInkRed,
                  ),
                ),
              ),
            );
          }),
        ),
      ]),
    );
  }
}

// ─── Rounds Badge ─────────────────────────────────────────────────────────────

class _RoundsBadge extends StatelessWidget {
  final int remaining;
  final int currentPartida;
  final int playerWins;
  final int opponentWins;
  const _RoundsBadge({required this.remaining, required this.currentPartida, required this.playerWins, required this.opponentWins});

  Widget _dot(bool filled) => Container(
    width: 9, height: 9,
    margin: const EdgeInsets.symmetric(horizontal: 2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: filled ? AppColors.primary : Colors.transparent,
      border: Border.all(color: AppColors.primary, width: 1.5),
    ),
  );

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;
    final isLast = remaining == 1;
    final roundLabel = isLast ? '⚡ ÚLTIMA RONDA ⚡' : 'RONDAS: $remaining';
    final roundColor = isLast ? AppColors.danger : purple;

    return Column(mainAxisSize: MainAxisSize.min, children: [
      // Match score
      Row(mainAxisSize: MainAxisSize.min, children: [
        Text('PARTIDA $currentPartida/3  ', style: AppText.caption.copyWith(letterSpacing: 1)),
        Row(children: List.generate(2, (i) => _dot(i < playerWins))),
        Text('  vs  ', style: AppText.caption),
        Row(children: List.generate(2, (i) => _dot(i < opponentWins))),
      ]),
      const SizedBox(height: 4),
      // Ronda badge
      AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xs + 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: roundColor, width: 1.5),
          boxShadow: [BoxShadow(color: roundColor.withValues(alpha: .28), blurRadius: 14)],
        ),
        child: Text(roundLabel, style: TextStyle(
            color: roundColor, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
      ),
    ]);
  }
}

// ─── Phase Hint ──────────────────────────────────────────────────────────────

class _PhaseHint extends StatelessWidget {
  final _Phase phase;
  final int peeksUsed;
  final int kingCount;
  final bool swapOwnSelected;
  final bool kingPickedOwn;
  final bool kingPickedOpp;
  const _PhaseHint({required this.phase, required this.peeksUsed, required this.kingCount,
    required this.swapOwnSelected, required this.kingPickedOwn, required this.kingPickedOpp});

  @override
  Widget build(BuildContext context) {
    String text = '';
    Color color = AppColors.textMuted;
    switch (phase) {
      case _Phase.peekInitial:
        text = peeksUsed == 0 ? 'Elegí 2 cartas para memorizar' : peeksUsed == 1 ? 'Elegí 1 carta más (${2 - peeksUsed} restante)' : 'Memorizalas bien... ⏳';
        color = AppColors.accent;
      case _Phase.powerPeekOwn:
        text = 'PODER: Tocá una carta tuya para ver';
        color = AppColors.accent;
      case _Phase.powerPeekOpponent:
        text = 'PODER: Tocá una carta del rival para ver';
        color = AppColors.warning;
      case _Phase.powerSwapSelectOwn:
        text = 'PODER: Elegí una de TUS cartas';
        color = AppColors.success;
      case _Phase.powerSwapSelectOpponent:
        text = 'PODER: Ahora tocá una carta del RIVAL';
        color = AppColors.success;
      case _Phase.powerKingPeek:
        if (!kingPickedOwn && !kingPickedOpp) {
          text = 'REY: Tocá 1 tuya y 1 del rival';
        } else if (kingPickedOwn) {
          text = 'REY: Ahora tocá 1 carta del RIVAL';
        } else {
          text = 'REY: Ahora tocá 1 carta TUYA';
        }
        color = AppColors.primary;
      case _Phase.powerKingDecide:
        text = '¿Intercambiás estas 2 cartas?';
        color = AppColors.primary;
      case _Phase.cardDrawn:
        text = 'Tocá una carta tuya para intercambiar · o tirá la robada';
        color = AppColors.textSecondary;
      default:
        text = '';
    }
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text, style: AppText.caption.copyWith(color: color, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center);
  }
}

// ─── Table Center ─────────────────────────────────────────────────────────────

class _TableCenter extends StatelessWidget {
  final int deckCount;
  final List<_DiscardEntry> discardStack;
  final GameCard? drawnCard;
  final bool canDraw;
  final VoidCallback onDrawCard;
  final VoidCallback onDiscardDrawn;

  const _TableCenter({
    required this.deckCount, required this.discardStack, required this.drawnCard,
    required this.canDraw, required this.onDrawCard, required this.onDiscardDrawn,
  });

  @override
  Widget build(BuildContext context) {
    final hasDraw = drawnCard != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            _DeckCard(width: hasDraw ? 80 : 100, count: deckCount, onTap: onDrawCard, canDraw: canDraw),
            Positioned(
              top: -6, right: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(AppRadius.pill),
                    boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: .5), blurRadius: 8)]),
                child: Text('$deckCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.xs),
          Text('MAZO', style: AppText.caption),
        ]),
        if (hasDraw) ...[
          const SizedBox(width: AppSpacing.md),
          Column(children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(drawnCard),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.elasticOut,
              builder: (ctx, scale, child) => Transform.scale(scale: scale, child: child),
              child: GestureDetector(
                onTap: onDiscardDrawn,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: .55), blurRadius: 22, spreadRadius: 3)],
                  ),
                  child: _CardFace(card: drawnCard!, width: 90),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text('TIRAR', style: AppText.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
        ],
        SizedBox(width: hasDraw ? AppSpacing.md : AppSpacing.xl2 + AppSpacing.base),
        Column(children: [
          _DiscardPile(stack: discardStack, width: hasDraw ? 90 : 100),
          const SizedBox(height: AppSpacing.xs),
          Text('DESCARTE', style: AppText.caption.copyWith(color: AppColors.primary)),
        ]),
      ],
    );
  }
}

// ─── Action Bar ───────────────────────────────────────────────────────────────

class _ActionBar extends StatelessWidget {
  final _Phase phase;
  final bool isOpponentTurn;
  final bool cutPending;
  final VoidCallback onCut;
  final VoidCallback onMirror;
  final VoidCallback onKingSwap;
  final VoidCallback onKingKeep;

  const _ActionBar({
    required this.phase, required this.isOpponentTurn, required this.cutPending,
    required this.onCut, required this.onMirror,
    required this.onKingSwap, required this.onKingKeep,
  });

  @override
  Widget build(BuildContext context) {
    // ESPEJO is a free action always available (except initial peek)
    final espejoBtn = Expanded(child: _Btn(
      label: '¡ESPEJO!', icon: Icons.copy_all_rounded,
      color: AppColors.success, solid: true, onTap: onMirror,
    ));

    if (phase == _Phase.peekInitial) return const SizedBox(height: 52);

    Widget child;
    if (phase == _Phase.powerKingDecide) {
      // Three buttons: cambiar | dejar | espejo
      child = Row(children: [
        Expanded(child: _Btn(label: 'CAMBIAR', icon: Icons.swap_horiz_rounded, color: AppColors.primary, solid: true, onTap: onKingSwap)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: _Btn(label: 'DEJAR', icon: Icons.close_rounded, color: AppColors.danger, solid: false, onTap: onKingKeep)),
        const SizedBox(width: AppSpacing.sm),
        espejoBtn,
      ]);
    } else if (phase == _Phase.turn || phase == _Phase.cardDrawn) {
      child = Row(children: [
        Expanded(child: _Btn(label: 'CORTAR', icon: Icons.content_cut_rounded, color: AppColors.danger, solid: cutPending, onTap: isOpponentTurn ? () {} : onCut, disabled: isOpponentTurn)),
        const SizedBox(width: AppSpacing.md),
        espejoBtn,
      ]);
    } else {
      // cardDrawn, powerPeek*, powerSwap*, powerKingPeek: espejo only
      child = Row(children: [espejoBtn]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: child,
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool solid;
  final bool disabled;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.icon, required this.color, required this.solid, required this.onTap, this.disabled = false});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled ? AppColors.textMuted : color;
    final bg = solid ? effectiveColor : effectiveColor.withValues(alpha: .15);
    final fg = solid ? AppColors.bgDeepest : effectiveColor;
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: effectiveColor, width: 1.5),
            boxShadow: disabled ? [] : [BoxShadow(color: effectiveColor.withValues(alpha: .30), blurRadius: 12)],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: fg, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: fg, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.1)),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Turn Indicator ──────────────────────────────────────────────────────────

class _TurnIndicator extends StatelessWidget {
  final bool isPlayerTurn;
  const _TurnIndicator({required this.isPlayerTurn});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isPlayerTurn ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          color: AppColors.accent.withValues(alpha: .12),
          border: Border.all(color: AppColors.accent.withValues(alpha: .5), width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.flash_on_rounded, color: AppColors.accent, size: 11),
          const SizedBox(width: 4),
          Text('TU TURNO', style: AppText.caption.copyWith(
              color: AppColors.accent, fontWeight: FontWeight.w700, fontSize: 11, letterSpacing: 1.5)),
        ]),
      ),
    );
  }
}

// ─── Player Hand ─────────────────────────────────────────────────────────────

class _PlayerHand extends StatelessWidget {
  final List<GameCard> playerCards;
  final _Phase phase;
  final int? revealingSlot;
  final Set<int> kingPeekedSlots;
  final Set<int> justSwappedSlots;
  final Set<int> initialPeekShowing;
  final int? swapOwnSlot;
  final bool ownKingEyeEnabled;
  final void Function(int) onTapCard;

  const _PlayerHand({
    required this.playerCards, required this.phase, required this.revealingSlot,
    required this.kingPeekedSlots, required this.justSwappedSlots,
    required this.initialPeekShowing, required this.swapOwnSlot,
    required this.ownKingEyeEnabled, required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(playerCards.length, (i) {
        final card = playerCards[i];
        final isRevealing = revealingSlot == i;
        final isKingPeeked = kingPeekedSlots.contains(i);
        final isInitialPeek = initialPeekShowing.contains(i);
        final justSwapped = justSwappedSlots.contains(i);
        final showFace = isRevealing || isKingPeeked || (isInitialPeek && !justSwapped);

        final isSwapOwn = swapOwnSlot == i;
        final eyeActive = phase == _Phase.powerPeekOwn || (ownKingEyeEnabled && !isKingPeeked);
        final tappable = switch (phase) {
          _Phase.peekInitial => !isInitialPeek,
          _Phase.cardDrawn => true,
          _Phase.powerPeekOwn => !isRevealing,
          _Phase.powerKingPeek => ownKingEyeEnabled && !isKingPeeked,
          _Phase.powerSwapSelectOwn => true,
          _ => false,
        };

        Color borderColor;
        if (isSwapOwn) {
          borderColor = AppColors.primary;
        } else if (phase == _Phase.cardDrawn) {
          borderColor = AppColors.accent;
        } else if (phase == _Phase.peekInitial) {
          borderColor = AppColors.accent;
        } else {
          borderColor = purple;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
          child: GestureDetector(
            onTap: tappable ? () => onTapCard(i) : null,
            child: _FlippableCard(
              key: ValueKey('p_${i}_${card.toString()}'),
              showFace: showFace,
              front: _CardFace(card: card, width: 72),
              back: _CardBack(
                width: 72,
                borderColor: borderColor,
                eyeActive: eyeActive,
                eyeColor: AppColors.accent,
                selected: isSwapOwn,
                patternColor: AppColors.accent,
              ),
            ),
          ),
        );
      }),
    );
  }
}
