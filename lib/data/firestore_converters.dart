import 'package:cloud_firestore/cloud_firestore.dart';

import 'room_doc.dart';

/// Firestore converter for `rooms/{roomCode}`. Use via
/// `firestore.collection('rooms').withConverter(roomConverter)`.
final roomConverter = FirestoreConverter<RoomDoc>(
  fromJson: RoomDoc.fromJson,
  toJson: (doc) => doc.toJson(),
);

/// Generic wrapper to pair fromJson + toJson into Firestore's converter API.
class FirestoreConverter<T> {
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  const FirestoreConverter({required this.fromJson, required this.toJson});

  T fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? _,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError('Snapshot ${snapshot.id} has no data');
    }
    return fromJson(data);
  }

  Map<String, dynamic> toFirestore(T value, SetOptions? _) => toJson(value);
}

extension FirestoreConverterCollection on FirestoreConverter<RoomDoc> {
  CollectionReference<RoomDoc> rooms(FirebaseFirestore db) =>
      db.collection('rooms').withConverter<RoomDoc>(
            fromFirestore: fromSnapshot,
            toFirestore: toFirestore,
          );
}
