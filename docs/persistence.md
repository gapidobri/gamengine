# Persistence Module

Import:

```dart
import 'package:gamengine/ecs.dart';
```

Persistence is exported through `ecs.dart` (`src/ecs/persistence/persistence.dart`).

## World-Only Save/Load

Use `WorldStateSerializer` + `WorldStatePersistence<T>`.

```dart
final serializer = WorldStateSerializer();
DefaultWorldComponentCodecs.register(serializer);

final persistence = WorldStatePersistence<String>(
  serializer: serializer,
  format: JsonWorldStateFormat(),
);

final saved = persistence.encodeWorld(world);
persistence.decodeIntoWorld(world, saved);
```

## World + System Snapshots

Use `EngineSnapshotSerializer` + `EngineSnapshotPersistence<T>`.

```dart
final serializer = WorldStateSerializer();
DefaultWorldComponentCodecs.register(serializer);

final snapshots = EngineSnapshotPersistence<String>(
  serializer: EngineSnapshotSerializer(worldSerializer: serializer),
  format: JsonWorldStateFormat(),
);

final saved = snapshots.encodeSnapshot(
  world,
  participants: <SnapshotParticipant>[particleSystem],
);

snapshots.decodeIntoWorld(
  world,
  saved,
  participants: <SnapshotParticipant>[particleSystem],
);
```

## Custom System Snapshot

```dart
class CooldownSystem extends System implements SnapshotParticipant {
  final Map<String, double> cooldowns = {};

  @override
  String get snapshotId => 'game.cooldowns';

  @override
  Object? exportSnapshot() => {'cooldowns': cooldowns};

  @override
  void importSnapshot(Object? snapshot) {
    cooldowns.clear();
    if (snapshot is Map && snapshot['cooldowns'] is Map) {
      final raw = Map<String, Object?>.from(snapshot['cooldowns'] as Map);
      raw.forEach((k, v) => cooldowns[k] = (v as num).toDouble());
    }
  }
}
```
