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

  static const List<GameCard?> playerHandCards = [
    GameCard.regular(Suit.spades, 13), // K♠
    null,
    GameCard.regular(Suit.diamonds, 1), // A♦
    null,
  ];
  static const List<bool> playerHandRevealed = [true, false, true, false];
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
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
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

// ─── Card Back ────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  final double width;
  final Color? glowColor;
  final bool showEye;

  const _CardBack({this.width = 72, this.glowColor, this.showEye = false});

  @override
  Widget build(BuildContext context) {
    final h = width / AppCardDims.aspectRatio;
    final glow = glowColor;

    return Container(
      width: width,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.cardBack,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: glow ?? AppColors.border,
          width: glow != null ? 1.5 : 1.0,
        ),
        boxShadow: [
          const BoxShadow(
              color: Colors.black54, blurRadius: 10, offset: Offset(0, 4)),
          if (glow != null)
            BoxShadow(
                color: glow.withValues(alpha: 0.35), blurRadius: 16, spreadRadius: 1),
        ],
      ),
      child: Stack(children: [
        Center(
          child: Icon(
            Icons.layers_rounded,
            color: AppColors.cardBackPattern.withValues(alpha: 0.45),
            size: width * 0.42,
          ),
        ),
        if (showEye)
          Positioned(
            top: 7,
            left: 0,
            right: 0,
            child: Center(
              child: Icon(
                Icons.visibility_outlined,
                color: (glow ?? AppColors.textMuted).withValues(alpha: 0.85),
                size: 13,
              ),
            ),
          ),
      ]),
    );
  }
}

// ─── Arena Screen ─────────────────────────────────────────────────────────────

class ArenaScreen extends StatelessWidget {
  const ArenaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDeepest,
      appBar: AppBar(
        backgroundColor: AppColors.bgDeepest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.menu_rounded, color: AppColors.textSecondary),
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
              const _OpponentSection(),
              const SizedBox(height: AppSpacing.base),
              const _RoundsBadge(),
              const Spacer(),
              const _TableCenter(),
              const SizedBox(height: AppSpacing.base),
              const _ActionButtons(),
              const SizedBox(height: AppSpacing.xl),
              const _PlayerHand(),
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
  const _OpponentSection();

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
          children: List.generate(
            4,
            (i) => Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
              child: const _CardBack(width: 68),
            ),
          ),
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

// ─── Table Center ─────────────────────────────────────────────────────────────

class _TableCenter extends StatelessWidget {
  const _TableCenter();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Draw pile
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
        // Discard pile
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
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.base),
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
  const _PlayerHand();

  @override
  Widget build(BuildContext context) {
    const purple = AppColors.cardInkJoker;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        final card = _Mock.playerHandCards[i];
        final revealed = _Mock.playerHandRevealed[i];
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 1),
          child: Stack(clipBehavior: Clip.none, children: [
            if (revealed && card != null)
              _CardFace(card: card, width: 72)
            else
              const _CardBack(
                width: 72,
                glowColor: purple,
                showEye: true,
              ),
            // eye icon on revealed cards too (subtle)
            if (revealed && card != null)
              Positioned(
                top: 7,
                left: 0,
                right: 0,
                child: Center(
                  child: Icon(
                    Icons.visibility_outlined,
                    color: AppColors.accent.withValues(alpha: 0.6),
                    size: 12,
                  ),
                ),
              ),
          ]),
        );
      }),
    );
  }
}
