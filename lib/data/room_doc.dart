import '../engine/models/game_state.dart';

/// Top-level Firestore document shape for a room.
/// Stored under `rooms/{roomCode}`.
class RoomDoc {
  final String roomCode;
  final RoomStatus status;
  final String hostId;
  final Map<String, PlayerInfo> players; // uid → info
  final List<String> seatOrder; // empty until 2 players joined
  final GameState? game; // null until host starts match
  final int? mirrorWindowClosesAtMs; // epoch ms; null when closed

  const RoomDoc({
    required this.roomCode,
    required this.status,
    required this.hostId,
    required this.players,
    required this.seatOrder,
    this.game,
    this.mirrorWindowClosesAtMs,
  });

  RoomDoc copyWith({
    RoomStatus? status,
    String? hostId,
    Map<String, PlayerInfo>? players,
    List<String>? seatOrder,
    Object? game = _sentinel,
    Object? mirrorWindowClosesAtMs = _sentinel,
  }) {
    return RoomDoc(
      roomCode: roomCode,
      status: status ?? this.status,
      hostId: hostId ?? this.hostId,
      players: players ?? this.players,
      seatOrder: seatOrder ?? this.seatOrder,
      game: identical(game, _sentinel) ? this.game : game as GameState?,
      mirrorWindowClosesAtMs: identical(mirrorWindowClosesAtMs, _sentinel)
          ? this.mirrorWindowClosesAtMs
          : mirrorWindowClosesAtMs as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'roomCode': roomCode,
        'status': status.code,
        'hostId': hostId,
        'players': players.map((k, v) => MapEntry(k, v.toJson())),
        'seatOrder': seatOrder,
        'game': game?.toJson(),
        'mirrorWindowClosesAtMs': mirrorWindowClosesAtMs,
      };

  factory RoomDoc.fromJson(Map<String, dynamic> json) => RoomDoc(
        roomCode: json['roomCode'] as String,
        status: RoomStatusCode.fromCode(json['status'] as String),
        hostId: json['hostId'] as String,
        players: (json['players'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, PlayerInfo.fromJson(v as Map<String, dynamic>)),
        ),
        seatOrder: (json['seatOrder'] as List<dynamic>).cast<String>(),
        game: json['game'] == null
            ? null
            : GameState.fromJson(json['game'] as Map<String, dynamic>),
        mirrorWindowClosesAtMs: (json['mirrorWindowClosesAtMs'] as num?)?.toInt(),
      );
}

class PlayerInfo {
  final String nickname;
  final int seat; // 0 or 1

  const PlayerInfo({required this.nickname, required this.seat});

  Map<String, dynamic> toJson() => {'nickname': nickname, 'seat': seat};

  factory PlayerInfo.fromJson(Map<String, dynamic> json) => PlayerInfo(
        nickname: json['nickname'] as String,
        seat: (json['seat'] as num).toInt(),
      );
}

enum RoomStatus { waiting, playing, finished }

extension RoomStatusCode on RoomStatus {
  String get code => name;
  static RoomStatus fromCode(String code) => RoomStatus.values.firstWhere(
        (s) => s.name == code,
        orElse: () => throw ArgumentError('Unknown RoomStatus: $code'),
      );
}

const _sentinel = Object();
