import 'package:gamengine/src/ecs/persistence/serializers/world_state_serializer.dart';
import 'package:gamengine/src/ecs/persistence/snapshots/snapshot_participant.dart';
import 'package:gamengine/src/ecs/world.dart';

class EngineSnapshotSerializer {
  final WorldStateSerializer worldSerializer;

  EngineSnapshotSerializer({required this.worldSerializer});

  Map<String, Object?> exportSnapshot(
    World world, {
    Iterable<SnapshotParticipant> participants = const <SnapshotParticipant>[],
    bool throwOnUnregisteredComponent = false,
  }) {
    final systems = <String, Object?>{};
    for (final participant in participants) {
      systems[participant.snapshotId] = participant.exportSnapshot();
    }

    return <String, Object?>{
      'schemaVersion': 1,
      'world': worldSerializer.exportWorld(
        world,
        throwOnUnregisteredComponent: throwOnUnregisteredComponent,
      ),
      'systems': systems,
    };
  }

  void importSnapshot(
    World world,
    Map<String, Object?> snapshot, {
    Iterable<SnapshotParticipant> participants = const <SnapshotParticipant>[],
    bool clearWorld = true,
    bool throwOnUnknownComponentType = false,
    bool clearMissingParticipantSnapshots = true,
  }) {
    final worldStateRaw = snapshot['world'];
    final worldState = worldStateRaw is Map
        ? Map<String, Object?>.from(worldStateRaw)
        : snapshot;

    worldSerializer.importWorld(
      world,
      worldState,
      clearWorld: clearWorld,
      throwOnUnknownComponentType: throwOnUnknownComponentType,
    );

    final systemsRaw = snapshot['systems'];
    final systems = systemsRaw is Map
        ? Map<String, Object?>.from(systemsRaw)
        : const <String, Object?>{};

    for (final participant in participants) {
      if (systems.containsKey(participant.snapshotId)) {
        participant.importSnapshot(systems[participant.snapshotId]);
      } else if (clearMissingParticipantSnapshots) {
        participant.importSnapshot(null);
      }
    }
  }
}
