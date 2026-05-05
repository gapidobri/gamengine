import 'package:gamengine/gamengine.dart';

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

        final encodedComponent = codec.encode(component);

        _serializeEntities(encodedComponent);

        components[codec.typeId] = encodedComponent;
      }

      entities.add(<String, Object?>{
        'id': entity.id,
        'components': components,
      });
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

    final entities = <int, Entity>{};

    for (final rawEntity in rawEntities) {
      entities[rawEntity['id']] = Entity(id: rawEntity['id']);
    }

    for (final rawEntity in rawEntities) {
      if (rawEntity is! Map) {
        throw FormatException('Entity entry must be an object map.');
      }

      final componentsRaw = rawEntity['components'];
      if (componentsRaw is! Map) {
        throw FormatException('Entity "components" must be an object map.');
      }

      final entity = entities[rawEntity['id']]!;

      for (final entry in componentsRaw.entries) {
        final typeId = entry.key.toString();
        final codec = _codecsById[typeId];
        if (codec == null) {
          if (throwOnUnknownComponentType) {
            throw StateError(
              'No serializer registered for component typeId $typeId.',
            );
          }
          continue;
        }

        final payload = entry.value;
        if (payload is! Map) {
          throw FormatException(
            'Component payload for $typeId must be an object map.',
          );
        }

        _deserializeEntities(payload, entities);

        entity.add(codec.decode(Map<String, Object?>.from(payload)));
      }

      world.addEntity(entity);
    }
  }

  void _serializeEntities(Object? value) {
    _serializeEntityValue(value);
  }

  void _deserializeEntities(Object? value, Map<int, Entity> entities) {
    _deserializeEntityValue(value, entities);
  }

  Object? _serializeEntityValue(Object? value) {
    switch (value) {
      case Entity(:final id):
        return {'\$entityRef': id};

      case Map<dynamic, dynamic> map:
        final keys = map.keys.toList(growable: false);
        for (final key in keys) {
          map[key] = _serializeEntityValue(map[key]);
        }
        return map;

      case List<dynamic> list:
        return list
            .map((value) => _serializeEntityValue(value))
            .toList(growable: false);

      case Set<dynamic> set:
        final updated = set.map(_serializeEntityValue).toList(growable: false);
        set
          ..clear()
          ..addAll(updated);
        return set;

      default:
        return value;
    }
  }

  Object? _deserializeEntityValue(Object? value, Map<int, Entity> entities) {
    switch (value) {
      case Map<dynamic, dynamic> map:
        final entityId = map['\$entityRef'];
        if (entityId is int) {
          return entities[entityId];
        }

        final keys = map.keys.toList(growable: false);
        for (final key in keys) {
          map[key] = _deserializeEntityValue(map[key], entities);
        }
        return map;

      case List<dynamic> list:
        for (var i = 0; i < list.length; i++) {
          list[i] = _deserializeEntityValue(list[i], entities);
        }
        return list;

      case Set<dynamic> set:
        final updated = set
            .map((value) => _deserializeEntityValue(value, entities))
            .toList(growable: false);
        set
          ..clear()
          ..addAll(updated);
        return set;

      default:
        return value;
    }
  }
}
