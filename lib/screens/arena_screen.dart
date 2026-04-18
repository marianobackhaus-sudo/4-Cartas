import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../engine/models/card.dart';

// ─── Types ────────────────────────────────────────────────────────────────────

class _DiscardEntry {
  final GameCard card;
  final double angle;
  final Offset offset;
  const _DiscardEntry(this.card, this.angle, this.offset);
}

// ─── Deck Builder ─────────────────────────────────────────────────────────────

List<GameCard> _buildFullDeck() {
  final cards = <GameCard>[];
  for (final suit in Suit.values) {
    for (int rank = 1; rank <= 13; rank++) {
      cards.add(GameCard.regular(suit, rank));
    }
  }
  cards.add(const GameCard.joker());
  cards.add(const GameCard.joker());
  return cards;
}

// ─── String / Color Helpers ───────────────────────────────────────────────────

String _suitSymbol(Suit s) {
  switch (s) {
    case Suit.hearts:
      return '♥';
    case Suit.diamonds:
      return '♦';
    case Suit.clubs:
      return '♣';
    case Suit.spades:
      return '♠';
  }
}

String _rankLabel(int r) {
  switch (r) {
    case 1:
      return 'A';
    case 11:
      return 'J';
    case 12:
      return 'Q';
    case 13:
      return 'K';
    default:
      return '$r';
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
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardFaceEdge),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          top: 5, left: 7,
          child: _CornerLabel(rnk: rnk, sym: sym, color: color),
        ),
        Center(
          child: Text(
            sym,
            style: TextStyle(
              color: color,
              fontSize: width * 0.30,
              height: 1,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Positioned(
          bottom: 5, right: 7,
          child: Transform.rotate(
            angle: math.pi,
            child: _CornerLabel(rnk: rnk, sym: sym, color: color),
          ),
        ),
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
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardInkJoker.withValues(alpha: 0.6)),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          BoxShadow(color: AppColors.cardInkJoker.withValues(alpha: 0.3), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('★', style: TextStyle(color: AppColors.cardInkJoker, fontSize: width * 0.28, height: 1)),
          Text('JKR', style: TextStyle(color: AppColors.cardInkJoker, fontSize: width * 0.14, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ),
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
      Text(rnk, style: s),
      Text(sym, style: s.copyWith(fontSize: 11)),
    ]);
  }
}

// ─── Card Back ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final double width;
  final Color? borderColor;
  final bool eyeActive;
  final Color eyeColor;

  const _CardBack({
    this.width = 72,
    this.borderColor,
    this.eyeActive = false,
    this.eyeColor = AppColors.accent,
  });

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    final bc = borderColor ?? (eyeActive ? eyeColor : AppColors.border);

    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.cardBack,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: bc, width: eyeActive ? 1.5 : 1.0),
        boxShadow: [
          const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          if (eyeActive)
            BoxShadow(color: eyeColor.withValues(alpha: 0.40), blurRadius: 18, spreadRadius: 2),
        ],
      ),
      child: eyeActive
          ? Center(
              child: Icon(Icons.visibility_outlined, color: eyeColor, size: width * 0.46),
            )
          : null,
    );
  }
}

// ─── Flip Card (3D Y-axis) ────────────────────────────────────────────────────

class _FlippableCard extends StatefulWidget {
  final bool showFace;
  final Widget front;
  final Widget back;

  const _FlippableCard({
    super.key,
    required this.showFace,
    required this.front,
    required this.back,
  });

  @override
  State<_FlippableCard> createState() => _FlippableCardState();
}

class _FlippableCardState extends State<_FlippableCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _anim = Tween<double>(begin: 0.0, end: math.pi)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.showFace) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_FlippableCard old) {
    super.didUpdateWidget(old);
    if (widget.showFace != old.showFace) {
      widget.showFace ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context2, child2) {
        final angle = _anim.value;
        final showFront = angle > math.pi / 2;
        return Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(showFront ? angle - math.pi : angle),
          alignment: Alignment.center,
          child: showFront ? widget.front : widget.back,
        );
      },
    );
  }
}

// ─── Deck Card (draw pile with stacked icon) ──────────────────────────────────

class _DeckCard extends StatelessWidget {
  final double width;
  final int count;
  final VoidCallback? onTap;
  final bool canDraw;

  const _DeckCard({
    this.width = 100,
    required this.count,
    this.onTap,
    this.canDraw = true,
  });

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    return GestureDetector(
      onTap: canDraw ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.cardBack,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: canDraw ? AppColors.primary.withValues(alpha: 0.7) : AppColors.border,
            width: canDraw ? 1.5 : 1.0,
          ),
          boxShadow: [
            const BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            if (canDraw)
              BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 14),
          ],
        ),
        child: Center(
          child: _StackedCardsIcon(size: width * 0.52),
        ),
      ),
    );
  }
}

class _StackedCardsIcon extends StatelessWidget {
  final double size;
  const _StackedCardsIcon({required this.size});

  Widget _miniCard(double angle, double opacity) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: size,
        height: size / AppCardDims.aspectRatio,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: opacity * 0.18),
          borderRadius: BorderRadius.circular(size * 0.12),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: opacity),
            width: 1.0,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size * 1.5,
      height: (size / AppCardDims.aspectRatio) * 1.35,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _miniCard(-0.28, 0.35),
          _miniCard(0.18, 0.55),
          _miniCard(0.0, 0.90),
        ],
      ),
    );
  }
}

// ─── Discard Pile (stacked, rotated cards) ────────────────────────────────────

class _DiscardPile extends StatelessWidget {
  final List<_DiscardEntry> stack;
  final double width;

  const _DiscardPile({required this.stack, this.width = 100});

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;

    if (stack.isEmpty) {
      return Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text('DESCARTE', style: AppText.caption),
        ),
      );
    }

    // Show max last 10 cards for performance
    final visible = stack.length > 10 ? stack.sublist(stack.length - 10) : stack;

    return SizedBox(
      // Extra space so rotated cards don't clip
      width: width + 28,
      height: h + 28,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: visible.map((e) {
          return Transform.translate(
            offset: e.offset,
            child: Transform.rotate(
              angle: e.angle,
              child: _CardFace(card: e.card, width: width),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Arena Screen ─────────────────────────────────────────────────────────────

class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  // ── peek powers ──────────────────────────────────────────────────────────────
  bool _opponentPeekActive = false;
  int? _revealingOpponentSlot;
  bool _playerPeekActive = false;
  int? _revealingPlayerSlot;
  Timer? _revealTimer;

  // ── game state ───────────────────────────────────────────────────────────────
  final _random = math.Random();
  late List<GameCard> _deck;
  late List<_DiscardEntry> _discardStack;
  late List<GameCard> _playerCards;
  late List<GameCard> _opponentCards;
  Set<int> _playerKnownSlots = {};
  Set<int> _justSwappedSlots = {};
  GameCard? _drawnCard;

  @override
  void initState() {
    super.initState();
    _initGame();
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  void _initGame() {
    final cards = _buildFullDeck()..shuffle(_random);
    _playerCards = List<GameCard>.from(cards.sublist(0, 4));
    _opponentCards = List<GameCard>.from(cards.sublist(4, 8));
    final firstDiscard = cards[8];
    _deck = List<GameCard>.from(cards.sublist(9));
    _discardStack = [_DiscardEntry(firstDiscard, _rAngle(), _rOffset())];
    _playerKnownSlots = {0, 2}; // initial peek
    _justSwappedSlots = {};
    _drawnCard = null;
  }

  double _rAngle() => (_random.nextDouble() - 0.5) * 0.52;
  Offset _rOffset() => Offset(
    (_random.nextDouble() - 0.5) * 14,
    (_random.nextDouble() - 0.5) * 10,
  );

  void _drawCard() {
    if (_drawnCard != null || _deck.isEmpty) return;
    setState(() {
      _drawnCard = _deck.removeLast();
    });
  }

  void _discardDrawn() {
    final card = _drawnCard;
    if (card == null) return;
    setState(() {
      _discardStack = [..._discardStack, _DiscardEntry(card, _rAngle(), _rOffset())];
      _drawnCard = null;
    });
  }

  void _swapWithSlot(int i) {
    final drawn = _drawnCard;
    if (drawn == null) return;
    final outCard = _playerCards[i];
    final newCards = List<GameCard>.from(_playerCards)..[i] = drawn;
    setState(() {
      _playerCards = newCards;
      _discardStack = [..._discardStack, _DiscardEntry(outCard, _rAngle(), _rOffset())];
      _drawnCard = null;
      _playerKnownSlots = {..._playerKnownSlots, i};
      _justSwappedSlots = {..._justSwappedSlots, i};
    });
    // Remove from justSwapped after one frame so flip animation triggers
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _justSwappedSlots = _justSwappedSlots.difference({i}));
    });
  }

  // ── peek power handlers ──────────────────────────────────────────────────────

  void _activateOpponentPeek() {
    _revealTimer?.cancel();
    setState(() {
      _opponentPeekActive = true;
      _playerPeekActive = false;
      _revealingOpponentSlot = null;
      _revealingPlayerSlot = null;
    });
  }

  void _activatePlayerPeek() {
    _revealTimer?.cancel();
    setState(() {
      _playerPeekActive = true;
      _opponentPeekActive = false;
      _revealingOpponentSlot = null;
      _revealingPlayerSlot = null;
    });
  }

  void _onTapOpponentCard(int i) {
    if (!_opponentPeekActive) return;
    _revealTimer?.cancel();
    setState(() {
      _revealingOpponentSlot = i;
      _opponentPeekActive = false;
    });
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _revealingOpponentSlot = null);
    });
  }

  void _onTapPlayerCard(int i) {
    if (_drawnCard != null) {
      _swapWithSlot(i);
      return;
    }
    if (!_playerPeekActive) return;
    _revealTimer?.cancel();
    setState(() {
      _revealingPlayerSlot = i;
      _playerPeekActive = false;
    });
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _revealingPlayerSlot = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
          onPressed: () {},
        ),
        title: const Text(
          '4 CARTAS BLITZ',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bgBase, AppColors.bgDeepest],
          ),
        ),
        child: SafeArea(
          child: Column(children: [
            _OpponentSection(
              opponentCards: _opponentCards,
              peekActive: _opponentPeekActive,
              revealingSlot: _revealingOpponentSlot,
              onTapCard: _onTapOpponentCard,
            ),
            const SizedBox(height: AppSpacing.base),
            const _RoundsBadge(),
            const SizedBox(height: AppSpacing.sm),
            _PowerDemoBar(
              onPeekOpponent: _activateOpponentPeek,
              onPeekOwn: _activatePlayerPeek,
              opponentPeekActive: _opponentPeekActive,
              playerPeekActive: _playerPeekActive,
            ),
            const Spacer(),
            _TableCenter(
              deckCount: _deck.length,
              discardStack: _discardStack,
              drawnCard: _drawnCard,
              canDraw: _drawnCard == null,
              onDrawCard: _drawCard,
              onDiscardDrawn: _discardDrawn,
            ),
            const SizedBox(height: AppSpacing.base),
            _ActionButtons(swapMode: _drawnCard != null),
            const SizedBox(height: AppSpacing.xl),
            _PlayerHand(
              playerCards: _playerCards,
              knownSlots: _playerKnownSlots,
              justSwappedSlots: _justSwappedSlots,
              revealingSlot: _revealingPlayerSlot,
              peekActive: _playerPeekActive,
              swapMode: _drawnCard != null,
              onTapCard: _onTapPlayerCard,
            ),
            const SizedBox(height: AppSpacing.lg),
          ]),
        ),
      ),
    );
  }
}

// ─── Opponent Section ─────────────────────────────────────────────────────────

class _OpponentSection extends StatelessWidget {
  final List<GameCard> opponentCards;
  final bool peekActive;
  final int? revealingSlot;
  final void Function(int) onTapCard;

  const _OpponentSection({
    required this.opponentCards,
    required this.peekActive,
    required this.revealingSlot,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.base, AppSpacing.base, 0),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.person_rounded, color: AppColors.textMuted, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('NEON_DRIFTER', style: AppText.titleSmall),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('Pensando...', style: AppText.caption.copyWith(
                  color: AppColors.success, fontWeight: FontWeight.w500)),
              ]),
            ]),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final isRevealing = revealingSlot == i;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
              child: GestureDetector(
                onTap: (peekActive && !isRevealing) ? () => onTapCard(i) : null,
                child: _FlippableCard(
                  showFace: isRevealing,
                  front: _CardFace(card: opponentCards[i], width: 68),
                  back: _CardBack(
                    width: 68,
                    eyeActive: peekActive,
                    eyeColor: AppColors.warning,
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
  const _RoundsBadge();

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl2, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: purple, width: 1.5),
        boxShadow: [BoxShadow(color: purple.withValues(alpha: 0.28), blurRadius: 14)],
      ),
      child: const Text(
        'RONDAS RESTANTES: 3',
        style: TextStyle(
          color: purple, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.5),
      ),
    );
  }
}

// ─── Power Demo Bar ───────────────────────────────────────────────────────────

class _PowerDemoBar extends StatelessWidget {
  final VoidCallback onPeekOpponent;
  final VoidCallback onPeekOwn;
  final bool opponentPeekActive;
  final bool playerPeekActive;

  const _PowerDemoBar({
    required this.onPeekOpponent,
    required this.onPeekOwn,
    required this.opponentPeekActive,
    required this.playerPeekActive,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('DEMO  ', style: AppText.caption.copyWith(
              fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          _DemoChip(
            label: '9/10: espiar rival',
            icon: Icons.visibility_outlined,
            color: AppColors.warning,
            active: opponentPeekActive,
            onTap: onPeekOpponent,
          ),
          const SizedBox(width: AppSpacing.sm),
          _DemoChip(
            label: '7/8: espiar propio',
            icon: Icons.visibility_outlined,
            color: AppColors.accent,
            active: playerPeekActive,
            onTap: onPeekOwn,
          ),
        ],
      ),
    );
  }
}

class _DemoChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  const _DemoChip({
    required this.label, required this.icon, required this.color,
    required this.active, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: active ? color : AppColors.border, width: active ? 1.5 : 1.0),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: active ? color : AppColors.textMuted, size: 11),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(
            color: active ? color : AppColors.textMuted,
            fontSize: 10,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.3,
          )),
        ]),
      ),
    );
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
    required this.deckCount,
    required this.discardStack,
    required this.drawnCard,
    required this.canDraw,
    required this.onDrawCard,
    required this.onDiscardDrawn,
  });

  @override
  Widget build(BuildContext context) {
    final hasDraw = drawnCard != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // ── MAZO ──────────────────────────────────────────────────────────────
        Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            _DeckCard(
              width: hasDraw ? 80 : 100,
              count: deckCount,
              onTap: onDrawCard,
              canDraw: canDraw,
            ),
            Positioned(
              top: -6, right: -8,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [BoxShadow(color: AppColors.accent.withValues(alpha: 0.5), blurRadius: 8)],
                ),
                child: Text(
                  '$deckCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text('MAZO', style: AppText.caption),
        ]),

        // ── CARTA ROBADA ──────────────────────────────────────────────────────
        if (hasDraw) ...[
          const SizedBox(width: AppSpacing.md),
          Column(children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(drawnCard),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.elasticOut,
              builder: (ctx, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: GestureDetector(
                onTap: onDiscardDrawn,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.55),
                        blurRadius: 22, spreadRadius: 3),
                    ],
                  ),
                  child: _CardFace(card: drawnCard!, width: 90),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('TIRAR', style: AppText.caption.copyWith(
                color: AppColors.primary, fontWeight: FontWeight.w700)),
          ]),
        ],

        SizedBox(width: hasDraw ? AppSpacing.md : AppSpacing.xl2 + AppSpacing.base),

        // ── DESCARTE ──────────────────────────────────────────────────────────
        Column(children: [
          _DiscardPile(stack: discardStack, width: hasDraw ? 90 : 100),
          const SizedBox(height: AppSpacing.sm),
          Text('DESCARTE', style: AppText.caption.copyWith(color: AppColors.primary)),
        ]),
      ],
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final bool swapMode;
  const _ActionButtons({this.swapMode = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: swapMode
          ? Center(
              child: Text(
                'Tocá una de tus cartas para intercambiar',
                style: AppText.caption.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            )
          : Row(children: [
              Expanded(child: _GameButton(
                label: 'CORTAR',
                icon: Icons.content_cut_rounded,
                color: AppColors.danger,
                solid: false,
                onTap: () {},
              )),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _GameButton(
                label: '¡ESPEJO!',
                icon: Icons.copy_all_rounded,
                color: AppColors.success,
                solid: true,
                onTap: () {},
              )),
            ]),
    );
  }
}

class _GameButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool solid;
  final VoidCallback onTap;

  const _GameButton({
    required this.label, required this.icon, required this.color,
    required this.solid, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = solid ? color : color.withValues(alpha: 0.15);
    final fg = solid ? AppColors.bgDeepest : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.30), blurRadius: 12)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(
              color: fg, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

// ─── Player Hand ─────────────────────────────────────────────────────────────

class _PlayerHand extends StatelessWidget {
  final List<GameCard> playerCards;
  final Set<int> knownSlots;
  final Set<int> justSwappedSlots;
  final int? revealingSlot;
  final bool peekActive;
  final bool swapMode;
  final void Function(int) onTapCard;

  const _PlayerHand({
    required this.playerCards,
    required this.knownSlots,
    required this.justSwappedSlots,
    required this.revealingSlot,
    required this.peekActive,
    required this.swapMode,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final card = playerCards[i];
        final isKnown = knownSlots.contains(i);
        final justSwapped = justSwappedSlots.contains(i);
        final isRevealing = revealingSlot == i;
        // Card is visible if known (and not in the brief "just swapped" moment)
        // or temporarily revealed by power
        final showFace = (isKnown && !justSwapped) || isRevealing;

        // Border color signals
        Color borderColor;
        if (swapMode) {
          borderColor = AppColors.primary; // gold = swap available
        } else if (peekActive) {
          borderColor = AppColors.accent;
        } else {
          borderColor = purple;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
          child: GestureDetector(
            onTap: () => onTapCard(i),
            child: _FlippableCard(
              // Key changes when card changes → new widget instance for fresh flip
              key: ValueKey('player_${i}_${card.toString()}'),
              showFace: showFace,
              front: _CardFace(card: card, width: 72),
              back: _CardBack(
                width: 72,
                borderColor: borderColor,
                eyeActive: peekActive && !isKnown,
                eyeColor: AppColors.accent,
              ),
            ),
          ),
        );
      }),
    );
  }
}
