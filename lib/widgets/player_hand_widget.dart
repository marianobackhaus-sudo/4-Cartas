import 'package:flutter/material.dart';

import '../core/design_tokens.dart';
import '../engine/models/hand_slot.dart';
import 'card_widget.dart';

/// Your own hand (4 slots). Cards are shown face-down by default; if the
/// slot has `knownToOwner=true` or `faceDown=false`, it renders face-up.
/// If [peekRevealIndices] is non-empty, those slots render face-up
/// regardless (used for the initial 2-card peek + 7/8 powers).
class PlayerHandWidget extends StatelessWidget {
  const PlayerHandWidget({
    super.key,
    required this.slots,
    this.selectedIndex,
    this.highlightedIndices = const {},
    this.disabledIndices = const {},
    this.peekRevealIndices = const {},
    this.onTapSlot,
  });

  final List<HandSlot> slots;
  final int? selectedIndex;
  final Set<int> highlightedIndices;
  final Set<int> disabledIndices;
  final Set<int> peekRevealIndices;
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
            disabled: disabledIndices.contains(i),
            onTap: onTapSlot == null ? null : () => onTapSlot!(i),
          ),
      ],
    );
  }

  bool _isFaceDown(HandSlot slot, int index) {
    if (peekRevealIndices.contains(index)) return false;
    if (!slot.faceDown) return false;
    // `knownToOwner` means the owner knows what card is here — render face-up
    // so the player can see it (this is "own info", not leaked to opponent).
    if (slot.knownToOwner) return false;
    return true;
  }
}
