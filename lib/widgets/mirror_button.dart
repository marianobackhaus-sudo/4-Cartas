import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/motion.dart';
import '../core/typography.dart';

/// Floating action button for attempting Espejito. Pulses while active.
class MirrorButton extends StatefulWidget {
  const MirrorButton({
    super.key,
    required this.enabled,
    required this.onTap,
  });

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<MirrorButton> createState() => _MirrorButtonState();
}

class _MirrorButtonState extends State<MirrorButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: AppMotion.mirrorPulse,
    );
    if (widget.enabled) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant MirrorButton old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.enabled && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.value = 0;
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
      animation: _ctrl,
      builder: (context, child) {
        final pulse = widget.enabled ? (0.5 + _ctrl.value * 0.5) : 0.25;
        return GestureDetector(
          onTap: widget.enabled ? widget.onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              color: widget.enabled
                  ? AppColors.primary
                  : AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: pulse),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.flip_rounded,
                  color: widget.enabled
                      ? AppColors.onPrimary
                      : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'ESPEJITO',
                  style: AppText.caption.copyWith(
                    color: widget.enabled
                        ? AppColors.onPrimary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
