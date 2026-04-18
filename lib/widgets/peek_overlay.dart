import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../core/typography.dart';
import '../engine/models/hand_slot.dart';
import 'card_widget.dart';

/// Initial 2-card peek UI. User picks up to 2 of their own slots to reveal,
/// then confirms. Presented as a full-screen modal during peekInitial.
class PeekOverlay extends StatefulWidget {
  const PeekOverlay({
    super.key,
    required this.slots,
    required this.onConfirm,
  });

  final List<HandSlot> slots;
  final Future<void> Function() onConfirm;

  @override
  State<PeekOverlay> createState() => _PeekOverlayState();
}

class _PeekOverlayState extends State<PeekOverlay> {
  final Set<int> _revealed = {};
  bool _busy = false;

  void _toggle(int i) {
    setState(() {
      if (_revealed.contains(i)) {
        _revealed.remove(i);
      } else if (_revealed.length < 2) {
        _revealed.add(i);
      }
    });
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      await widget.onConfirm();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceOverlay,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('ESPIÁ 2 DE TUS CARTAS',
                  style: AppText.label, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              const Text('Tocá hasta 2 cartas para ver qué son.',
                  style: AppText.body, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.xl2),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.sm,
                children: [
                  for (var i = 0; i < widget.slots.length; i++)
                    CardWidget(
                      card: widget.slots[i].card,
                      faceDown: !_revealed.contains(i),
                      selected: _revealed.contains(i),
                      onTap: _busy ? null : () => _toggle(i),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl2),
              ElevatedButton(
                onPressed: _busy ? null : _confirm,
                child: Text(_busy ? 'Listo...' : 'Listo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
