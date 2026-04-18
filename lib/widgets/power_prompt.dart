import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../engine/models/pending_action.dart';

/// Short human-readable label for a pending power, shown in a banner to the
/// player who just discarded a power card.
class PowerPrompt extends StatelessWidget {
  const PowerPrompt({
    super.key,
    required this.pending,
    this.extra,
  });

  final PendingAction pending;

  /// Optional extra line rendered below the prompt (e.g. "Tocá una de tus cartas").
  final String? extra;

  @override
  Widget build(BuildContext context) {
    final (title, body) = _copy(pending);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppText.bodyStrong.copyWith(color: AppColors.primary)),
          const SizedBox(height: AppSpacing.xs),
          Text(body, style: AppText.body),
          if (extra != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(extra!,
                style: AppText.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  (String, String) _copy(PendingAction p) {
    switch (p) {
      case PendingPeekOwn():
        return ('PODER ${p.rank}', 'Mirá una de tus propias cartas. Cuando termines, tocá "Listo".');
      case PendingPeekOpponent():
        return ('PODER ${p.rank}', 'Mirá una carta del rival. Cuando termines, tocá "Listo".');
      case PendingSwap():
        return (
          p.rank == 11 ? 'PODER J' : 'PODER Q',
          'Intercambiá una carta tuya con una del rival.'
        );
      case PendingKingPeek():
        if (!p.isComplete) {
          return ('PODER K', 'Espiá 2 cartas (propias o del rival). Después podrás decidir si intercambiar.');
        }
        return ('PODER K — DECIDIR',
            'Elegí 2 slots para swap, o tocá "No cambiar".');
    }
  }
}
