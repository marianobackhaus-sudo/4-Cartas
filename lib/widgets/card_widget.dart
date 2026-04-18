import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';
import '../core/typography.dart';
import '../engine/models/card.dart';

/// A single playing card. Two states: face-down (showing back) or face-up.
/// Supports selection + highlight + press feedback + 3D-ish flip animation.
class CardWidget extends StatefulWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.faceDown = true,
    this.selected = false,
    this.highlighted = false,
    this.disabled = false,
    this.width = AppCardDims.defaultWidth,
    this.onTap,
  });

  final GameCard? card;
  final bool faceDown;
  final bool selected;
  final bool highlighted;
  final bool disabled;
  final double width;
  final VoidCallback? onTap;

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipCtrl;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: AppMotion.cardFlip,
      value: widget.faceDown ? 0 : 1,
    );
  }

  @override
  void didUpdateWidget(covariant CardWidget old) {
    super.didUpdateWidget(old);
    if (old.faceDown != widget.faceDown) {
      if (widget.faceDown) {
        _flipCtrl.reverse();
      } else {
        _flipCtrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.width / AppCardDims.aspectRatio;
    final borderColor = widget.highlighted
        ? AppColors.accent
        : (widget.selected ? AppColors.primary : Colors.transparent);

    return AnimatedScale(
      duration: AppMotion.pressFeedback,
      curve: AppMotion.pressCurve,
      scale: widget.selected ? 1.04 : 1.0,
      child: _PressFeedback(
        enabled: widget.onTap != null && !widget.disabled,
        onTap: widget.onTap,
        child: AnimatedOpacity(
          duration: AppDurations.fast,
          opacity: widget.disabled ? 0.5 : 1,
          child: AnimatedBuilder(
            animation: _flipCtrl,
            builder: (context, child) {
              final t = _flipCtrl.value;
              final angle = t * math.pi;
              final showingFront = t > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008)
                  ..rotateY(angle),
                child: Container(
                  width: widget.width,
                  height: height,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: borderColor, width: 2),
                    boxShadow: widget.highlighted
                        ? [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              spreadRadius: 1,
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.card - 2),
                    child: showingFront
                        ? Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: _CardFace(card: widget.card),
                          )
                        : const _CardBack(),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PressFeedback extends StatefulWidget {
  const _PressFeedback({
    required this.child,
    required this.enabled,
    required this.onTap,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_PressFeedback> createState() => _PressFeedbackState();
}

class _PressFeedbackState extends State<_PressFeedback> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: widget.enabled ? () => setState(() => _down = false) : null,
      onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        duration: AppMotion.pressFeedback,
        curve: AppMotion.pressCurve,
        scale: _down ? AppPressScale.card : 1.0,
        child: widget.child,
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cardBack, AppColors.surfaceElevated],
        ),
      ),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.cardBackPattern, width: 2),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: const Icon(Icons.star_border_rounded,
              color: AppColors.cardBackPattern, size: 28),
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({required this.card});

  final GameCard? card;

  @override
  Widget build(BuildContext context) {
    final c = card;
    if (c == null) {
      return Container(color: AppColors.cardFace);
    }
    if (c.isJoker) {
      return _JokerFace();
    }
    final isRed = c.suit == Suit.hearts || c.suit == Suit.diamonds;
    final ink = isRed ? AppColors.cardInkRed : AppColors.cardInkBlack;
    final rankText = _rankLabel(c.rank);
    final suit = _suitGlyph(c.suit!);

    return Container(
      color: AppColors.cardFace,
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Stack(
        children: [
          Positioned(
            top: 2,
            left: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(rankText,
                    style: AppText.cardCorner.copyWith(color: ink)),
                Text(suit,
                    style: AppText.cardCorner.copyWith(color: ink)),
              ],
            ),
          ),
          Center(
            child: Text(
              suit,
              style: AppText.cardRank.copyWith(color: ink, fontSize: 36),
            ),
          ),
          Positioned(
            bottom: 2,
            right: 4,
            child: Transform.rotate(
              angle: math.pi,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(rankText,
                      style: AppText.cardCorner.copyWith(color: ink)),
                  Text(suit,
                      style: AppText.cardCorner.copyWith(color: ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return 'A';
      case 11:
        return 'J';
      case 12:
        return 'Q';
      case 13:
        return 'K';
      default:
        return '$rank';
    }
  }

  String _suitGlyph(Suit s) {
    switch (s) {
      case Suit.hearts:
        return '\u2665';
      case Suit.diamonds:
        return '\u2666';
      case Suit.clubs:
        return '\u2663';
      case Suit.spades:
        return '\u2660';
    }
  }
}

class _JokerFace extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardFace,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star_rounded,
                color: AppColors.cardInkJoker, size: 32),
            Text('JOKER',
                style: AppText.cardCorner
                    .copyWith(color: AppColors.cardInkJoker, letterSpacing: 2)),
            Text('-2',
                style: AppText.cardCorner
                    .copyWith(color: AppColors.cardInkJoker)),
          ],
        ),
      ),
    );
  }
}
