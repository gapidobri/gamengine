import 'package:gamengine/src/ecs/persistence/formats/world_state_format.dart';
import 'package:gamengine/src/ecs/persistence/serializers/world_state_serializer.dart';
import 'package:gamengine/src/ecs/persistence/storage/world_state_storage.dart';
import 'package:gamengine/src/ecs/world.dart';

class WorldStatePersistence<TSerialized> {
  final WorldStateSerializer serializer;
  final WorldStateFormat<TSerialized> format;

  WorldStatePersistence({
    required this.serializer,
    required this.format,
  });

  TSerialized encodeWorld(
    World world, {
    bool throwOnUnregisteredComponent = false,
  }) {
    final map = serializer.exportWorld(
      world,
      throwOnUnregisteredComponent: throwOnUnregisteredComponent,
    );
    return format.encode(map);
  }

  void decodeIntoWorld(
    World world,
    TSerialized serialized, {
    bool clearWorld = true,
    bool throwOnUnknownComponentType = false,
  }) {
    final map = format.decode(serialized);
    serializer.importWorld(
      world,
      map,
      clearWorld: clearWorld,
      throwOnUnknownComponentType: throwOnUnknownComponentType,
    );
  }

  Future<void> saveTo(
    World world, {
    required String location,
    required WorldStateStorage<TSerialized> storage,
    bool throwOnUnregisteredComponent = false,
  }) async {
    final serialized = encodeWorld(
      world,
      throwOnUnregisteredComponent: throwOnUnregisteredComponent,
    );
    await storage.write(location, serialized);
  }

  Future<void> loadFrom(
    World world, {
    required String location,
    required WorldStateStorage<TSerialized> storage,
    bool clearWorld = true,
    bool throwOnUnknownComponentType = false,
  }) async {
    final serialized = await storage.read(location);
    decodeIntoWorld(
      world,
      serialized,
      clearWorld: clearWorld,
      throwOnUnknownComponentType: throwOnUnknownComponentType,
    );
  }
}
