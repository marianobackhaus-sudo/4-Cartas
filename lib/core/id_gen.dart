import 'dart:math';

const _roomCodeAlphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String generateRoomCode({int length = 6}) {
  final rng = Random.secure();
  final buffer = StringBuffer();
  for (var i = 0; i < length; i++) {
    buffer.write(_roomCodeAlphabet[rng.nextInt(_roomCodeAlphabet.length)]);
  }
  return buffer.toString();
}
