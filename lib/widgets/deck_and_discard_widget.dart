import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';
import '../core/typography.dart';
import '../engine/models/card.dart';
import 'card_widget.dart';

/// Center table element: deck (left) + discard pile (right) + optional drawn
/// card preview floating above deck.
class DeckAndDiscardWidget extends StatelessWidget {
  const DeckAndDiscardWidget({
    super.key,
    required this.deckCount,
    required this.topDiscard,
    this.drawnCard,
    this.canDraw = false,
    this.canSwap = false,
    this.canDiscard = false,
    this.onDrawTap,
    this.onDiscardTap,
  });

  final int deckCount;
  final GameCard? topDiscard;
  final GameCard? drawnCard;
  final bool canDraw;
  final bool canSwap;
  final bool canDiscard;
  final VoidCallback? onDrawTap;
  final VoidCallback? onDiscardTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // A stacked "deck" visual: 3 cards behind the tap target.
                for (var offset = 2; offset >= 0; offset--)
                  Positioned(
                    left: offset * 2.0,
                    top: offset * 2.0,
                    child: Opacity(
                      opacity: offset == 0 ? 1 : 0.6,
                      child: IgnorePointer(
                        ignoring: offset != 0,
                        child: CardWidget(
                          card: null,
                          faceDown: true,
                          highlighted: offset == 0 && canDraw,
                          onTap: offset == 0 && canDraw ? onDrawTap : null,
                        ),
                      ),
                    ),
                  ),
                if (drawnCard != null)
                  Positioned(
                    left: AppCardDims.defaultWidth + AppSpacing.md,
                    top: -AppSpacing.xl,
                    child: AnimatedSwitcher(
                      duration: AppMotion.dealOne,
                      switchInCurve: AppMotion.dealCurve,
                      child: CardWidget(
                        key: ValueKey(drawnCard),
                        card: drawnCard,
                        faceDown: false,
                        highlighted: canSwap || canDiscard,
                        width: AppCardDims.featuredWidth,
                        onTap: canDiscard ? onDiscardTap : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('MAZO · $deckCount', style: AppText.caption),
          ],
        ),
        const SizedBox(width: AppSpacing.xl2),
        Column(
          children: [
            if (topDiscard != null)
              CardWidget(
                card: topDiscard,
                faceDown: false,
              )
            else
              _EmptyDiscard(),
            const SizedBox(height: AppSpacing.sm),
            const Text('DESCARTE', style: AppText.caption),
          ],
        ),
      ],
    );
  }
}

class _EmptyDiscard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final h = AppCardDims.defaultWidth / AppCardDims.aspectRatio;
    return Container(
      width: AppCardDims.defaultWidth,
      height: h,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.border,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Icon(Icons.auto_stories_outlined,
            color: AppColors.textMuted.withValues(alpha: 0.5)),
      ),
    );
  }
}
