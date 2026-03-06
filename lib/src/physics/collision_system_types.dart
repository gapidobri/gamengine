part of 'collision_system.dart';

typedef CollisionCheck<TA extends CollisionShape, TB extends CollisionShape> =
    bool Function({
      required Transform transformA,
      required TA colliderA,
      required Transform transformB,
      required TB colliderB,
      required CollisionManifold manifold,
    });

class CollisionManifold {
  final Vector2 normal = Vector2.zero();
  final Vector2 contactPoint = Vector2.zero();
  double penetration = 0;
}

class _ColliderEntry {
  final Entity entity;
  final Transform transform;
  final RigidBody? body;
  final CollisionShape collider;

  const _ColliderEntry({
    required this.entity,
    required this.transform,
    required this.body,
    required this.collider,
  });
}

typedef _CollisionEvaluator =
    bool Function({
      required Transform transformA,
      required CollisionShape colliderA,
      required Transform transformB,
      required CollisionShape colliderB,
      required CollisionManifold manifold,
    });

class _CollisionRegistration {
  final bool Function(CollisionShape a, CollisionShape b) matches;
  final _CollisionEvaluator evaluate;

  const _CollisionRegistration({required this.matches, required this.evaluate});
}
