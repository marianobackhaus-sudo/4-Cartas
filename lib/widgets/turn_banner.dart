import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';
import '../core/typography.dart';

/// Ribbon at the top of the game screen showing whose turn it is.
class TurnBanner extends StatelessWidget {
  const TurnBanner({
    super.key,
    required this.isMyTurn,
    required this.label,
  });

  final bool isMyTurn;
  final String label;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.turnBanner,
      curve: AppMotion.turnBannerCurve,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isMyTurn
            ? AppColors.accent.withValues(alpha: 0.16)
            : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isMyTurn ? AppColors.accent : AppColors.divider,
            width: isMyTurn ? 2 : 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMyTurn ? Icons.play_arrow_rounded : Icons.hourglass_top_rounded,
            color: isMyTurn ? AppColors.accent : AppColors.textMuted,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: AppText.titleSmall.copyWith(
              color: isMyTurn ? AppColors.accent : AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
