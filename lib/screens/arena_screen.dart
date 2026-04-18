import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../engine/models/card.dart';

// ─── Mock Data ────────────────────────────────────────────────────────────────

class _Mock {
  static const String opponentName = 'NEON_DRIFTER';
  static const int roundsRemaining = 3;
  static const int deckCount = 42;
  static const GameCard discardTop = GameCard.regular(Suit.clubs, 7);

  // Cartas reales del rival (ocultas — solo visibles al usar poder 9/10)
  static const List<GameCard> opponentCards = [
    GameCard.regular(Suit.hearts, 5),
    GameCard.regular(Suit.diamonds, 3),
    GameCard.regular(Suit.spades, 8),
    GameCard.regular(Suit.clubs, 2),
  ];

  // Cartas del jugador (ocultas — se pekan 2 al inicio, luego quedan boca abajo)
  static const List<GameCard> playerCards = [
    GameCard.regular(Suit.spades, 13), // K♠
    GameCard.regular(Suit.hearts, 9),  // desconocida
    GameCard.regular(Suit.diamonds, 1), // A♦
    GameCard.regular(Suit.clubs, 6),   // desconocida
  ];
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

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
          BoxShadow(
              color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      child: Stack(children: [
        Positioned(
          top: 5,
          left: 7,
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
          bottom: 5,
          right: 7,
          child: Transform.rotate(
            angle: math.pi,
            child: _CornerLabel(rnk: rnk, sym: sym, color: color),
          ),
        ),
      ]),
    );
  }
}

class _CornerLabel extends StatelessWidget {
  final String rnk, sym;
  final Color color;

  const _CornerLabel(
      {required this.rnk, required this.sym, required this.color});

  @override
  Widget build(BuildContext context) {
    final s = TextStyle(
        color: color, fontWeight: FontWeight.w800, height: 1.1, fontSize: 13);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(rnk, style: s),
      Text(sym, style: s.copyWith(fontSize: 11)),
    ]);
  }
}

// ─── Flip Card (3D Y-axis) ────────────────────────────────────────────────────

class _FlippableCard extends StatefulWidget {
  final bool showFace;
  final Widget front;
  final Widget back;

  const _FlippableCard({
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
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _anim = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
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

// ─── Card Back ────────────────────────────────────────────────────────────────

/// eyeActive: muestra el ojo grande en el centro (poder activo).
/// borderColor: nulo = borde estándar.
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
    final bw = eyeActive ? 1.5 : 1.0;

    return Container(
        width: width,
        height: h,
        decoration: BoxDecoration(
          color: AppColors.cardBack,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: bc, width: bw),
          boxShadow: [
            const BoxShadow(
                color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
            if (eyeActive)
              BoxShadow(
                  color: eyeColor.withValues(alpha: 0.40),
                  blurRadius: 18,
                  spreadRadius: 2),
          ],
        ),
        child: eyeActive
            ? Center(
                child: Icon(
                  Icons.visibility_outlined,
                  color: eyeColor,
                  size: width * 0.46,
                ),
              )
            : null,
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
  // Poder 9/10: espiar carta rival
  bool _opponentPeekActive = false;
  int? _revealingOpponentSlot;

  // Poder 7/8: espiar carta propia
  bool _playerPeekActive = false;
  int? _revealingPlayerSlot;

  Timer? _revealTimer;

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

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
      _opponentPeekActive = false; // poder consumido
    });
    _revealTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _revealingOpponentSlot = null);
    });
  }

  void _onTapPlayerCard(int i) {
    if (!_playerPeekActive) return;
    _revealTimer?.cancel();
    setState(() {
      _revealingPlayerSlot = i;
      _playerPeekActive = false; // poder consumido
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
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.textSecondary),
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
          child: Column(
            children: [
              _OpponentSection(
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
              const _TableCenter(),
              const SizedBox(height: AppSpacing.base),
              const _ActionButtons(),
              const SizedBox(height: AppSpacing.xl),
              _PlayerHand(
                peekActive: _playerPeekActive,
                revealingSlot: _revealingPlayerSlot,
                onTapCard: _onTapPlayerCard,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Opponent Section ─────────────────────────────────────────────────────────

class _OpponentSection extends StatelessWidget {
  final bool peekActive;
  final int? revealingSlot;
  final void Function(int) onTapCard;

  const _OpponentSection({
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.person_rounded,
                  color: AppColors.textMuted, size: 26),
            ),
            const SizedBox(width: AppSpacing.md),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_Mock.opponentName, style: AppText.titleSmall),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Pensando...',
                  style: AppText.caption.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
              child: GestureDetector(
                onTap: (peekActive && !isRevealing) ? () => onTapCard(i) : null,
                child: _FlippableCard(
                  showFace: isRevealing,
                  front: _CardFace(card: _Mock.opponentCards[i], width: 68),
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
        boxShadow: [
          BoxShadow(
            color: purple.withValues(alpha: 0.28),
            blurRadius: 14,
          ),
        ],
      ),
      child: Text(
        'RONDAS RESTANTES: ${_Mock.roundsRemaining}',
        style: const TextStyle(
          color: purple,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5,
        ),
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
          Text('DEMO  ',
              style: AppText.caption.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
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
    required this.label,
    required this.icon,
    required this.color,
    required this.active,
    required this.onTap,
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
          border: Border.all(
            color: active ? color : AppColors.border,
            width: active ? 1.5 : 1.0,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon,
              color: active ? color : AppColors.textMuted, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: active ? color : AppColors.textMuted,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Table Center ─────────────────────────────────────────────────────────────

class _TableCenter extends StatelessWidget {
  const _TableCenter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Column(children: [
          Stack(clipBehavior: Clip.none, children: [
            const _CardBack(width: 100),
            Positioned(
              top: -6,
              right: -8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Text(
                  '${_Mock.deckCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.sm),
          Text('MAZO', style: AppText.caption),
        ]),
        const SizedBox(width: AppSpacing.xl2 + AppSpacing.base),
        Column(children: [
          _CardFace(card: _Mock.discardTop, width: 100),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'DESCARTE',
            style: AppText.caption.copyWith(color: AppColors.primary),
          ),
        ]),
      ],
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      child: Row(children: [
        Expanded(
          child: _GameButton(
            label: 'CORTAR',
            icon: Icons.content_cut_rounded,
            color: AppColors.danger,
            solid: false,
            onTap: () {},
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _GameButton(
            label: '¡ESPEJO!',
            icon: Icons.copy_all_rounded,
            color: AppColors.success,
            solid: true,
            onTap: () {},
          ),
        ),
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
    required this.label,
    required this.icon,
    required this.color,
    required this.solid,
    required this.onTap,
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
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.30),
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: fg, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Player Hand ─────────────────────────────────────────────────────────────

class _PlayerHand extends StatelessWidget {
  final bool peekActive;
  final int? revealingSlot;
  final void Function(int) onTapCard;

  const _PlayerHand({
    required this.peekActive,
    required this.revealingSlot,
    required this.onTapCard,
  });

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final isRevealing = revealingSlot == i;
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
          child: GestureDetector(
            onTap: (peekActive && !isRevealing) ? () => onTapCard(i) : null,
            child: _FlippableCard(
              showFace: isRevealing,
              front: _CardFace(card: _Mock.playerCards[i], width: 72),
              back: _CardBack(
                width: 72,
                borderColor: peekActive ? AppColors.accent : purple,
                eyeActive: peekActive,
                eyeColor: AppColors.accent,
              ),
            ),
          ),
        );
      }),
    );
  }
}
