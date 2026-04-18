import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';

/// Context-sensitive action bar at the bottom of the game screen.
/// Buttons appear/disappear with AnimatedSwitcher.
class ActionBar extends StatelessWidget {
  const ActionBar({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.fast,
      switchInCurve: AppMotion.toastCurve,
      child: Container(
        key: ValueKey(children.map((e) => e.key).join(',')),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (final c in children) Expanded(child: c),
          ],
        ),
      ),
    );
  }
}
