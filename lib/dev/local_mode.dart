import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../data/room_doc.dart';
import '../data/room_repository.dart';
import '../engine/deck.dart';
import '../engine/models/game_state.dart';
import '../engine/rules.dart' as engine_rules;
import '../state/auth_providers.dart';
import '../state/providers.dart';

/// Toggle to run the app without Firebase. Hardcoded users, in-memory rooms.
/// Flip to false once Firebase is configured.
const bool kLocalMode = true;

/// Hardcoded player identities for local testing.
const String kLocalPlayerAUid = 'player-a';
const String kLocalPlayerBUid = 'player-b';
const String kLocalPlayerANick = 'Martín';
const String kLocalPlayerBNick = 'Rival';

/// Which hardcoded player this device is currently impersonating. Toggle via
/// the dev "Cambiar jugador" button in the game screen.
final currentLocalUidProvider =
    StateProvider<String>((_) => kLocalPlayerAUid);

/// Provider overrides to apply to `ProviderScope` when [kLocalMode] is true.
List<Override> buildLocalOverrides() {
  final room = _LocalRoomRepository();
  return [
    roomRepositoryProvider.overrideWithValue(room),
    authRepositoryProvider.overrideWithValue(_LocalAuthRepository()),
    currentUserIdProvider.overrideWith((ref) async {
      return ref.watch(currentLocalUidProvider);
    }),
  ];
}

// ── Mock auth ────────────────────────────────────────────────────────────────

class _LocalAuthRepository implements AuthRepository {
  @override
  String? get currentUid => kLocalPlayerAUid;

  @override
  Future<String> ensureSignedIn() async => kLocalPlayerAUid;
}

// ── In-memory room store ─────────────────────────────────────────────────────

class _LocalRoomRepository implements RoomRepository {
  final Map<String, RoomDoc> _rooms = {};
  final Map<String, StreamController<RoomDoc?>> _streams = {};

  @override
  Future<RoomDoc> createRoom({
    required String hostUid,
    required String hostNickname,
    int maxTries = 5,
  }) async {
    // Always use a fixed code for local testing so the "Unirse" button works
    // predictably. If the host creates twice, it replaces the prior room.
    const code = 'LOCAL1';
    final doc = RoomDoc(
      roomCode: code,
      status: RoomStatus.waiting,
      hostId: hostUid,
      players: {
        hostUid: PlayerInfo(nickname: hostNickname, seat: 0),
      },
      seatOrder: [hostUid],
    );
    _rooms[code] = doc;
    _emit(code);
    return doc;
  }

  @override
  Future<RoomDoc> joinRoom({
    required String code,
    required String uid,
    required String nickname,
  }) async {
    final current = _rooms[code];
    if (current == null) {
      throw StateError('Sala no encontrada');
    }
    if (current.players.containsKey(uid)) return current;
    if (current.players.length >= 2) {
      throw StateError('Sala llena');
    }
    final updated = current.copyWith(
      players: {
        ...current.players,
        uid: PlayerInfo(nickname: nickname, seat: 1),
      },
      seatOrder: [...current.seatOrder, uid],
    );
    _rooms[code] = updated;
    _emit(code);
    return updated;
  }

  @override
  Stream<RoomDoc?> watch(String code) {
    final ctrl = _streams.putIfAbsent(
      code,
      () => StreamController<RoomDoc?>.broadcast(),
    );
    // Emit current value asynchronously so listeners attach first.
    scheduleMicrotask(() {
      if (!ctrl.isClosed) ctrl.add(_rooms[code]);
    });
    return ctrl.stream;
  }

  @override
  Future<void> startFirstGame(String code) async {
    final doc = _rooms[code];
    if (doc == null) throw StateError('Sala no encontrada');
    if (doc.status != RoomStatus.waiting) return;
    if (doc.seatOrder.length != 2) {
      throw StateError('Se necesitan 2 jugadores');
    }
    final initial = engine_rules.setupInitialState(
      seatOrder: doc.seatOrder,
      shuffledDeck: shuffleDeck(buildDeck()),
    );
    _rooms[code] = doc.copyWith(status: RoomStatus.playing, game: initial);
    _emit(code);
  }

  @override
  Future<void> updateGame({
    required String code,
    required GameState Function(GameState current) update,
    RoomStatus? status,
    int? mirrorWindowClosesAtMs,
  }) async {
    final doc = _rooms[code];
    if (doc == null) throw StateError('Sala no encontrada');
    final current = doc.game;
    if (current == null) {
      throw StateError('Sala sin partida en curso');
    }
    final next = update(current);
    _rooms[code] = doc.copyWith(
      game: next,
      status: status,
      mirrorWindowClosesAtMs: mirrorWindowClosesAtMs,
    );
    _emit(code);
  }

  @override
  Future<void> replaceGame({
    required String code,
    required GameState next,
    RoomStatus? status,
  }) async {
    final doc = _rooms[code];
    if (doc == null) throw StateError('Sala no encontrada');
    _rooms[code] = doc.copyWith(game: next, status: status);
    _emit(code);
  }

  @override
  Future<void> delete(String code) async {
    _rooms.remove(code);
    _emit(code);
  }

  void _emit(String code) {
    final ctrl = _streams[code];
    if (ctrl != null && !ctrl.isClosed) ctrl.add(_rooms[code]);
  }
}
