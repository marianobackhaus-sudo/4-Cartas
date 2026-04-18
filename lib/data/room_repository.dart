import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/id_gen.dart';
import '../engine/deck.dart';
import '../engine/models/game_state.dart';
import '../engine/rules.dart' as engine_rules;
import 'firestore_converters.dart';
import 'room_doc.dart';

/// CRUD + streaming for room docs. Uses Firestore transactions so concurrent
/// writes (especially MirrorAttempt races) are serialized.
class RoomRepository {
  RoomRepository(this._db);

  final FirebaseFirestore _db;

  CollectionReference<RoomDoc> get _rooms => roomConverter.rooms(_db);

  /// Creates a new room owned by [hostUid]. Retries up to [maxTries] times
  /// in the (unlikely) case of code collision.
  Future<RoomDoc> createRoom({
    required String hostUid,
    required String hostNickname,
    int maxTries = 5,
  }) async {
    for (var attempt = 0; attempt < maxTries; attempt++) {
      final code = generateRoomCode();
      final ref = _rooms.doc(code);
      final existing = await ref.get();
      if (existing.exists) continue;
      final doc = RoomDoc(
        roomCode: code,
        status: RoomStatus.waiting,
        hostId: hostUid,
        players: {
          hostUid: PlayerInfo(nickname: hostNickname, seat: 0),
        },
        seatOrder: [hostUid],
      );
      await ref.set(doc);
      return doc;
    }
    throw StateError('Could not allocate unique room code after $maxTries tries');
  }

  /// Joins room [code] as the second player. Throws if full or not found.
  Future<RoomDoc> joinRoom({
    required String code,
    required String uid,
    required String nickname,
  }) {
    final ref = _rooms.doc(code);
    return _db.runTransaction<RoomDoc>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Sala no encontrada');
      }
      final current = snap.data()!;
      if (current.players.containsKey(uid)) return current;
      if (current.players.length >= 2) {
        throw StateError('Sala llena');
      }
      if (current.status != RoomStatus.waiting) {
        throw StateError('La sala ya empezó');
      }
      final updated = current.copyWith(
        players: {
          ...current.players,
          uid: PlayerInfo(nickname: nickname, seat: 1),
        },
        seatOrder: [...current.seatOrder, uid],
      );
      tx.set(ref, updated);
      return updated;
    });
  }

  /// Real-time stream of the room doc. Emits null if deleted.
  Stream<RoomDoc?> watch(String code) =>
      _rooms.doc(code).snapshots().map((s) => s.data());

  /// Host boots the first game of a match. Builds + shuffles the deck and
  /// sets `game` to the initial state.
  Future<void> startFirstGame(String code) async {
    final ref = _rooms.doc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Sala no encontrada');
      final doc = snap.data()!;
      if (doc.status != RoomStatus.waiting) return;
      if (doc.seatOrder.length != 2) {
        throw StateError('Se necesitan 2 jugadores');
      }
      final initial = engine_rules.setupInitialState(
        seatOrder: doc.seatOrder,
        shuffledDeck: shuffleDeck(buildDeck()),
      );
      tx.set(
        ref,
        doc.copyWith(status: RoomStatus.playing, game: initial),
      );
    });
  }

  /// Applies `updater` to the current state atomically. Typical usage: the
  /// game controller reads local state, runs engine.apply, and passes the new
  /// GameState back via this method.
  Future<void> updateGame({
    required String code,
    required GameState Function(GameState current) update,
    RoomStatus? status,
    int? mirrorWindowClosesAtMs,
  }) async {
    final ref = _rooms.doc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Sala no encontrada');
      final doc = snap.data()!;
      final currentGame = doc.game;
      if (currentGame == null) {
        throw StateError('Sala sin partida en curso');
      }
      final next = update(currentGame);
      tx.set(
        ref,
        doc.copyWith(
          game: next,
          status: status,
          mirrorWindowClosesAtMs: mirrorWindowClosesAtMs,
        ),
      );
    });
  }

  /// Completely replaces the game state (used for startNextRound/startNextGame
  /// where the caller produces a fresh deck off-transaction).
  Future<void> replaceGame({
    required String code,
    required GameState next,
    RoomStatus? status,
  }) async {
    final ref = _rooms.doc(code);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw StateError('Sala no encontrada');
      final doc = snap.data()!;
      tx.set(ref, doc.copyWith(game: next, status: status));
    });
  }

  Future<void> delete(String code) async {
    await _rooms.doc(code).delete();
  }
}
