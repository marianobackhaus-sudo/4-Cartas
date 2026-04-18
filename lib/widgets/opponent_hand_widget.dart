import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../engine/models/hand_slot.dart';
import 'card_widget.dart';

/// Opponent's hand — always face-down from your perspective except during
/// reveal (phase transitions), or when a slot is forced face-up by a mirror
/// miss (`faceDown=false` on the slot).
class OpponentHandWidget extends StatelessWidget {
  const OpponentHandWidget({
    super.key,
    required this.slots,
    this.revealAll = false,
    this.peekRevealIndices = const {},
    this.highlightedIndices = const {},
    this.selectedIndex,
    this.onTapSlot,
  });

  final List<HandSlot> slots;
  final bool revealAll;
  final Set<int> peekRevealIndices;
  final Set<int> highlightedIndices;
  final int? selectedIndex;
  final ValueChanged<int>? onTapSlot;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < slots.length; i++)
          CardWidget(
            card: slots[i].card,
            faceDown: _isFaceDown(slots[i], i),
            selected: selectedIndex == i,
            highlighted: highlightedIndices.contains(i),
            onTap: onTapSlot == null ? null : () => onTapSlot!(i),
          ),
      ],
    );
  }

  bool _isFaceDown(HandSlot slot, int index) {
    if (revealAll) return false;
    if (peekRevealIndices.contains(index)) return false;
    if (!slot.faceDown) return false; // flipped by mirror penalty
    return true;
  }
}
