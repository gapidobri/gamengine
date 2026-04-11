import 'package:gamengine/gamengine.dart';

class TransformHierarchySystem extends System {
  @override
  void update(double dt, World world, Commands commands) {
    final visiting = <Entity>{};
    final resolved = <Entity>{};

    for (final entity in world.query2<Parent, Transform>()) {
      _resolveEntity(entity, visiting, resolved);
    }
  }

  void _resolveEntity(
    Entity entity,
    Set<Entity> visiting,
    Set<Entity> resolved,
  ) {
    final parentRef = entity.tryGet<Parent>();
    final childTransform = entity.tryGet<Transform>();
    if (parentRef == null || childTransform == null) return;

    if (!visiting.add(entity)) {
      throw StateError(
        'Cycle detected in parent hierarchy at entity ${entity.id}.',
      );
    }

    _resolveEntity(parentRef.parent, visiting, resolved);

    final parentTransform = parentRef.parent.tryGet<Transform>();
    final localTransform = entity.tryGet<LocalTransform>();
    if (parentTransform == null || localTransform == null) {
      visiting.remove(entity);
      resolved.add(entity);
      return;
    }

    final rotatedOffset = localTransform.position.rotated(
      parentTransform.rotation,
    );

    childTransform.position
      ..setFrom(parentTransform.position)
      ..add(rotatedOffset);
    childTransform.rotation =
        parentTransform.rotation + localTransform.rotation;
    childTransform.scale
      ..setFrom(parentTransform.scale)
      ..multiply(localTransform.scale);

    visiting.remove(entity);
    resolved.add(entity);
  }
}
