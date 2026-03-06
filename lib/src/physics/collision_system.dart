import 'dart:math' as math;

import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/events/event_bus.dart';
import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/physics/collision_event.dart';
import 'package:gamengine/src/physics/components/collider.dart';
import 'package:gamengine/src/physics/components/colliders/rectangle_collider.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:vector_math/vector_math_64.dart';

part 'collision_system_checks.dart';
part 'collision_system_resolution.dart';
part 'collision_system_types.dart';

class CollisionSystem extends System {
  final World world;
  final EventBus? eventBus;
  final double positionCorrectionPercent;
  final double positionCorrectionSlop;

  final Vector2 _relativeVelocity = Vector2.zero();
  final Vector2 _velocityA = Vector2.zero();
  final Vector2 _velocityB = Vector2.zero();
  final Vector2 _contactOffsetA = Vector2.zero();
  final Vector2 _contactOffsetB = Vector2.zero();
  final Vector2 _impulse = Vector2.zero();
  final Vector2 _tangent = Vector2.zero();
  final Vector2 _normalProjection = Vector2.zero();
  final CollisionManifold _manifold = CollisionManifold();
  final List<_ColliderEntry> _colliders = <_ColliderEntry>[];
  final List<_CollisionRegistration> _checks = <_CollisionRegistration>[];
  final List<CollisionEvent> _events = <CollisionEvent>[];

  CollisionSystem({
    required this.world,
    this.eventBus,
    this.positionCorrectionPercent = 0.8,
    this.positionCorrectionSlop = 0.01,
  }) {
    registerCheck<Collider, Collider>(_checkCircleCircle);
    registerCheck<RectangleCollider, RectangleCollider>(
      _checkRectangleRectangle,
    );
    registerCheck<RectangleCollider, Collider>(_checkRectangleCircle);
  }

  @override
  int get priority => 490;

  List<CollisionEvent> get events => _events;

  void registerCheck<TA extends CollisionShape, TB extends CollisionShape>(
    CollisionCheck<TA, TB> check, {
    bool symmetric = true,
  }) {
    _checks.add(
      _CollisionRegistration(
        matches: (CollisionShape a, CollisionShape b) => a is TA && b is TB,
        evaluate:
            ({
              required Transform transformA,
              required CollisionShape colliderA,
              required Transform transformB,
              required CollisionShape colliderB,
              required CollisionManifold manifold,
            }) => check(
              transformA: transformA,
              colliderA: colliderA as TA,
              transformB: transformB,
              colliderB: colliderB as TB,
              manifold: manifold,
            ),
      ),
    );

    if (!symmetric || TA == TB) {
      return;
    }

    _checks.add(
      _CollisionRegistration(
        matches: (CollisionShape a, CollisionShape b) => a is TB && b is TA,
        evaluate:
            ({
              required Transform transformA,
              required CollisionShape colliderA,
              required Transform transformB,
              required CollisionShape colliderB,
              required CollisionManifold manifold,
            }) {
              final hit = check(
                transformA: transformB,
                colliderA: colliderB as TA,
                transformB: transformA,
                colliderB: colliderA as TB,
                manifold: manifold,
              );
              if (hit) {
                manifold.normal.scale(-1);
              }
              return hit;
            },
      ),
    );
  }

  @override
  void update(double dt) {
    _events.clear();
    if (dt <= 0) {
      return;
    }

    _collectColliders();

    for (var i = 0; i < _colliders.length; i++) {
      final entryA = _colliders[i];

      for (var j = i + 1; j < _colliders.length; j++) {
        final entryB = _colliders[j];
        if (entryA.entity == entryB.entity) {
          continue;
        }

        final check = _resolveCheck(entryA.collider, entryB.collider);
        if (check == null) {
          continue;
        }

        if (!check(
          transformA: entryA.transform,
          colliderA: entryA.collider,
          transformB: entryB.transform,
          colliderB: entryB.collider,
          manifold: _manifold,
        )) {
          continue;
        }

        final relativeSpeed = _closingSpeed(
          transformA: entryA.transform,
          bodyA: entryA.body,
          contactPointA: _manifold.contactPoint,
          transformB: entryB.transform,
          bodyB: entryB.body,
          contactPointB: _manifold.contactPoint,
          normal: _manifold.normal,
        );

        final event = CollisionEvent(
          entityA: entryA.entity,
          entityB: entryB.entity,
          point: Vector2.copy(_manifold.contactPoint),
          normal: Vector2.copy(_manifold.normal),
          relativeSpeed: relativeSpeed,
          penetration: _manifold.penetration,
        );
        _events.add(event);
        eventBus?.emit(event);

        _resolvePosition(
          transformA: entryA.transform,
          bodyA: entryA.body,
          transformB: entryB.transform,
          bodyB: entryB.body,
          normal: _manifold.normal,
          penetration: _manifold.penetration,
        );
        _resolveVelocity(
          transformA: entryA.transform,
          bodyA: entryA.body,
          colliderA: entryA.collider,
          contactPointA: _manifold.contactPoint,
          transformB: entryB.transform,
          bodyB: entryB.body,
          colliderB: entryB.collider,
          contactPointB: _manifold.contactPoint,
          normal: _manifold.normal,
          restitution: math.min(
            entryA.collider.restitution,
            entryB.collider.restitution,
          ),
          staticFriction: math.sqrt(
            entryA.collider.staticFriction * entryB.collider.staticFriction,
          ),
          dynamicFriction: math.sqrt(
            entryA.collider.dynamicFriction * entryB.collider.dynamicFriction,
          ),
        );
      }
    }
  }

  void _collectColliders() {
    _colliders.clear();
    for (final entity in world.entities) {
      final transform = entity.tryGet<Transform>();
      if (transform == null) {
        continue;
      }

      final body = entity.tryGet<RigidBody>();
      for (final component in entity.components) {
        if (component is! CollisionShape || !component.enabled) {
          continue;
        }
        _colliders.add(
          _ColliderEntry(
            entity: entity,
            transform: transform,
            body: body,
            collider: component,
          ),
        );
      }
    }
  }

  _CollisionEvaluator? _resolveCheck(CollisionShape a, CollisionShape b) {
    for (final registration in _checks) {
      if (registration.matches(a, b)) {
        return registration.evaluate;
      }
    }
    return null;
  }
}
