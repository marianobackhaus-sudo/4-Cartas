import 'hand_slot.dart';

class PlayerState {
  final String uid;
  final List<HandSlot> slots;

  const PlayerState({required this.uid, required this.slots});

  PlayerState copyWith({String? uid, List<HandSlot>? slots}) {
    return PlayerState(
      uid: uid ?? this.uid,
      slots: slots ?? this.slots,
    );
  }

  int get handScore => slots.fold<int>(0, (sum, s) => sum + s.card.value);

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  factory PlayerState.fromJson(Map<String, dynamic> json) => PlayerState(
        uid: json['uid'] as String,
        slots: (json['slots'] as List<dynamic>)
            .map((e) => HandSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
