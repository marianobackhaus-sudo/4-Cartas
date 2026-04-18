import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';

/// Shows round progress (R x/N) and match progress (Partida x/3).
class ScorePanel extends StatelessWidget {
  const ScorePanel({
    super.key,
    required this.roundIndex,
    required this.totalRounds,
    required this.gameIndex,
    required this.myGamesWon,
    required this.oppGamesWon,
    this.goldenRound = false,
  });

  final int roundIndex;
  final int totalRounds;
  final int gameIndex;
  final int myGamesWon;
  final int oppGamesWon;
  final bool goldenRound;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.bgBase,
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _Chip(
            label: 'RONDA',
            value: '${roundIndex + 1}/$totalRounds',
            accent: goldenRound ? AppColors.primary : null,
          ),
          if (goldenRound)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.xxs),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text('GOLDEN',
                  style: AppText.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  )),
            ),
          _Chip(
            label: 'PARTIDA',
            value: '${gameIndex + 1}/3',
          ),
          _Chip(
            label: 'GANADAS',
            value: '$myGamesWon–$oppGamesWon',
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(label, style: AppText.caption),
        Text(value,
            style: AppText.scoreNumeric.copyWith(
              fontSize: 18,
              color: accent ?? AppColors.textPrimary,
            )),
      ],
    );
  }
}
