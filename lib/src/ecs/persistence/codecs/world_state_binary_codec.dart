import 'dart:typed_data';

abstract class WorldStateBinaryCodec {
  String get formatId;

  Uint8List encodeBinary(Map<String, Object?> worldState);

  Map<String, Object?> decodeBinary(Uint8List bytes);
}
