import 'dart:convert';

import 'package:gamengine/src/ecs/persistence/formats/world_state_format.dart';

class JsonWorldStateFormat extends WorldStateFormat<String> {
  @override
  String get formatId => 'json';

  @override
  String encode(Map<String, Object?> worldState) {
    return jsonEncode(worldState);
  }

  @override
  Map<String, Object?> decode(String serialized) {
    final decoded = jsonDecode(serialized);
    if (decoded is! Map) {
      throw FormatException('World state root must be a JSON object.');
    }
    return Map<String, Object?>.from(decoded);
  }
}
