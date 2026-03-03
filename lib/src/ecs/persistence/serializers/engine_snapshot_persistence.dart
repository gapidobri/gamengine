import 'package:gamengine/src/ecs/persistence/formats/world_state_format.dart';
import 'package:gamengine/src/ecs/persistence/serializers/engine_snapshot_serializer.dart';
import 'package:gamengine/src/ecs/persistence/snapshots/snapshot_participant.dart';
import 'package:gamengine/src/ecs/persistence/storage/world_state_storage.dart';
import 'package:gamengine/src/ecs/world.dart';

class EngineSnapshotPersistence<TSerialized> {
  final EngineSnapshotSerializer serializer;
  final WorldStateFormat<TSerialized> format;

  EngineSnapshotPersistence({required this.serializer, required this.format});

  TSerialized encodeSnapshot(
    World world, {
    Iterable<SnapshotParticipant> participants = const <SnapshotParticipant>[],
    bool throwOnUnregisteredComponent = false,
  }) {
    final map = serializer.exportSnapshot(
      world,
      participants: participants,
      throwOnUnregisteredComponent: throwOnUnregisteredComponent,
    );
    return format.encode(map);
  }

  void decodeIntoWorld(
    World world,
    TSerialized serialized, {
    Iterable<SnapshotParticipant> participants = const <SnapshotParticipant>[],
    bool clearWorld = true,
    bool throwOnUnknownComponentType = false,
    bool clearMissingParticipantSnapshots = true,
  }) {
    final map = format.decode(serialized);
    serializer.importSnapshot(
      world,
      map,
      participants: participants,
      clearWorld: clearWorld,
      throwOnUnknownComponentType: throwOnUnknownComponentType,
      clearMissingParticipantSnapshots: clearMissingParticipantSnapshots,
    );
  }

  Future<void> saveTo(
    World world, {
    required String location,
    required WorldStateStorage<TSerialized> storage,
    Iterable<SnapshotParticipant> participants = const <SnapshotParticipant>[],
    bool throwOnUnregisteredComponent = false,
  }) async {
    final serialized = encodeSnapshot(
      world,
      participants: participants,
      throwOnUnregisteredComponent: throwOnUnregisteredComponent,
    );
    await storage.write(location, serialized);
  }

  Future<void> loadFrom(
    World world, {
    required String location,
    required WorldStateStorage<TSerialized> storage,
    Iterable<SnapshotParticipant> participants = const <SnapshotParticipant>[],
    bool clearWorld = true,
    bool throwOnUnknownComponentType = false,
    bool clearMissingParticipantSnapshots = true,
  }) async {
    final serialized = await storage.read(location);
    decodeIntoWorld(
      world,
      serialized,
      participants: participants,
      clearWorld: clearWorld,
      throwOnUnknownComponentType: throwOnUnknownComponentType,
      clearMissingParticipantSnapshots: clearMissingParticipantSnapshots,
    );
  }
}
