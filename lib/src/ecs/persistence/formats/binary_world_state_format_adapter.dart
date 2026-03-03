import 'dart:typed_data';

import 'package:gamengine/src/ecs/persistence/codecs/world_state_binary_codec.dart';
import 'package:gamengine/src/ecs/persistence/formats/world_state_format.dart';

class BinaryWorldStateFormatAdapter extends WorldStateFormat<Uint8List> {
  final WorldStateBinaryCodec codec;

  BinaryWorldStateFormatAdapter(this.codec);

  @override
  String get formatId => codec.formatId;

  @override
  Uint8List encode(Map<String, Object?> worldState) {
    return codec.encodeBinary(worldState);
  }

  @override
  Map<String, Object?> decode(Uint8List serialized) {
    return codec.decodeBinary(serialized);
  }
}
