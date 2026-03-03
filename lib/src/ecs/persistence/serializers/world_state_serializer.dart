import 'package:gamengine/src/ecs/components/component.dart';
import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/persistence/codecs/component_codec.dart';
import 'package:gamengine/src/ecs/world.dart';

class WorldStateSerializer {
  final Map<Type, ComponentCodec<Component>> _codecsByType =
      <Type, ComponentCodec<Component>>{};
  final Map<String, ComponentCodec<Component>> _codecsById =
      <String, ComponentCodec<Component>>{};

  void registerCodec<T extends Component>(ComponentCodec<T> codec) {
    _codecsByType[T] = codec as ComponentCodec<Component>;
    _codecsById[codec.typeId] = codec as ComponentCodec<Component>;
  }

  bool unregisterCodecByType<T extends Component>() {
    final codec = _codecsByType.remove(T);
    if (codec == null) {
      return false;
    }
    _codecsById.remove(codec.typeId);
    return true;
  }

  Map<String, Object?> exportWorld(
    World world, {
    bool throwOnUnregisteredComponent = false,
  }) {
    final entities = <Object?>[];

    for (final entity in world.entities) {
      final components = <String, Object?>{};

      for (final component in entity.components) {
        final codec = _codecsByType[component.runtimeType];
        if (codec == null) {
          if (throwOnUnregisteredComponent) {
            throw StateError(
              'No serializer registered for component type '
              '${component.runtimeType}.',
            );
          }
          continue;
        }

        components[codec.typeId] = codec.encode(component);
      }

      entities.add(<String, Object?>{'components': components});
    }

    return <String, Object?>{
      'schemaVersion': 1,
      'entityCount': world.entityCount,
      'entities': entities,
    };
  }

  void importWorld(
    World world,
    Map<String, Object?> state, {
    bool clearWorld = true,
    bool throwOnUnknownComponentType = false,
  }) {
    final rawEntities = state['entities'];
    if (rawEntities is! List) {
      throw FormatException('Expected "entities" list in world state.');
    }

    if (clearWorld) {
      world.clear();
    }

    for (final rawEntity in rawEntities) {
      if (rawEntity is! Map) {
        throw FormatException('Entity entry must be an object map.');
      }

      final componentsRaw = rawEntity['components'];
      if (componentsRaw is! Map) {
        throw FormatException('Entity "components" must be an object map.');
      }

      final entity = Entity();

      for (final entry in componentsRaw.entries) {
        final typeId = entry.key.toString();
        final codec = _codecsById[typeId];
        if (codec == null) {
          if (throwOnUnknownComponentType) {
            throw StateError('No serializer registered for component typeId $typeId.');
          }
          continue;
        }

        final payload = entry.value;
        if (payload is! Map) {
          throw FormatException('Component payload for $typeId must be an object map.');
        }

        entity.add(codec.decode(Map<String, Object?>.from(payload)));
      }

      world.addEntity(entity);
    }
  }
}
