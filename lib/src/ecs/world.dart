import 'package:gamengine/src/ecs/components/component.dart';
import 'package:gamengine/src/ecs/entity.dart';

class World {
  final List<Entity> _entities = <Entity>[];

  Iterable<Entity> get entities => _entities;
  int get entityCount => _entities.length;

  void addEntity(Entity entity) {
    _entities.add(entity);
  }

  void removeEntity(Entity entity) {
    _entities.remove(entity);
  }

  void clear() {
    _entities.clear();
  }

  Iterable<Entity> query<T extends Component>() sync* {
    for (final entity in _entities) {
      if (entity.tryGet<T>() != null) {
        yield entity;
      }
    }
  }

  Iterable<Entity> query2<T1 extends Component, T2 extends Component>() sync* {
    for (final entity in _entities) {
      if (entity.tryGet<T1>() != null && entity.tryGet<T2>() != null) {
        yield entity;
      }
    }
  }
}
