import 'dart:math' as math;

import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/events/event_bus.dart';
import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/physics/collision_event.dart';
import 'package:gamengine/src/physics/components/collider.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:vector_math/vector_math_64.dart';

class CollisionSystem extends System {
  final World world;
  final EventBus? eventBus;
  final double positionCorrectionPercent;
  final double positionCorrectionSlop;

  final Vector2 _normal = Vector2.zero();
  final Vector2 _contactPoint = Vector2.zero();
  final Vector2 _relativeVelocity = Vector2.zero();
  final Vector2 _impulse = Vector2.zero();
  final Vector2 _tangent = Vector2.zero();
  final Vector2 _normalProjection = Vector2.zero();
  final List<CollisionEvent> _events = <CollisionEvent>[];

  CollisionSystem({
    required this.world,
    this.eventBus,
    this.positionCorrectionPercent = 0.8,
    this.positionCorrectionSlop = 0.01,
  });

  @override
  int get priority => 490;

  List<CollisionEvent> get events => _events;

  @override
  void update(double dt) {
    _events.clear();
    if (dt <= 0) {
      return;
    }

    final colliders = <Entity>[];
    for (final entity in world.entities) {
      if (entity.get<Collider>() != null && entity.get<Transform>() != null) {
        colliders.add(entity);
      }
    }

    for (var i = 0; i < colliders.length; i++) {
      final entityA = colliders[i];
      final colliderA = world.get<Collider>(entityA);
      if (!colliderA.enabled || colliderA.radius <= 0) {
        continue;
      }
      final transformA = world.get<Transform>(entityA);
      final bodyA = entityA.get<RigidBody>();

      for (var j = i + 1; j < colliders.length; j++) {
        final entityB = colliders[j];
        final colliderB = world.get<Collider>(entityB);
        if (!colliderB.enabled || colliderB.radius <= 0) {
          continue;
        }
        final transformB = world.get<Transform>(entityB);
        final bodyB = entityB.get<RigidBody>();

        _normal
          ..setFrom(transformB.position)
          ..sub(transformA.position);

        final dist2 = _normal.length2;
        final radiusSum = colliderA.radius + colliderB.radius;
        final radiusSum2 = radiusSum * radiusSum;
        if (dist2 >= radiusSum2) {
          continue;
        }

        final distance = dist2 == 0 ? 0.0 : math.sqrt(dist2);
        if (distance > 0) {
          _normal.scale(1.0 / distance);
        } else {
          _normal
            ..x = 1
            ..y = 0;
        }
        final penetration = radiusSum - distance;
        final relativeSpeed = _closingSpeed(bodyA: bodyA, bodyB: bodyB);

        _contactPoint
          ..setFrom(_normal)
          ..scale(colliderA.radius)
          ..add(transformA.position);

        final event = CollisionEvent(
          entityA: entityA,
          entityB: entityB,
          point: Vector2.copy(_contactPoint),
          normal: Vector2.copy(_normal),
          relativeSpeed: relativeSpeed,
          penetration: penetration,
        );
        _events.add(event);
        eventBus?.emit(event);

        _resolvePosition(
          transformA: transformA,
          bodyA: bodyA,
          transformB: transformB,
          bodyB: bodyB,
          penetration: penetration,
        );
        _resolveVelocity(
          bodyA: bodyA,
          bodyB: bodyB,
          restitution: math.min(colliderA.restitution, colliderB.restitution),
          staticFriction: math.sqrt(
            colliderA.staticFriction * colliderB.staticFriction,
          ),
          dynamicFriction: math.sqrt(
            colliderA.dynamicFriction * colliderB.dynamicFriction,
          ),
        );
      }
    }
  }

  void _resolvePosition({
    required Transform transformA,
    required RigidBody? bodyA,
    required Transform transformB,
    required RigidBody? bodyB,
    required double penetration,
  }) {
    final invMassA = bodyA?.inverseMass ?? 0.0;
    final invMassB = bodyB?.inverseMass ?? 0.0;
    final invMassSum = invMassA + invMassB;
    if (invMassSum <= 0) {
      return;
    }

    final correctedPenetration = math.max(
      0.0,
      penetration - positionCorrectionSlop,
    );
    if (correctedPenetration <= 0) {
      return;
    }

    final correctionMag =
        (correctedPenetration * positionCorrectionPercent) / invMassSum;
    transformA.position.addScaled(_normal, -correctionMag * invMassA);
    transformB.position.addScaled(_normal, correctionMag * invMassB);
  }

  void _resolveVelocity({
    required RigidBody? bodyA,
    required RigidBody? bodyB,
    required double restitution,
    required double staticFriction,
    required double dynamicFriction,
  }) {
    final invMassA = bodyA?.inverseMass ?? 0.0;
    final invMassB = bodyB?.inverseMass ?? 0.0;
    final invMassSum = invMassA + invMassB;
    if (invMassSum <= 0) {
      return;
    }

    _relativeVelocity
      ..setZero()
      ..add(bodyB?.velocity ?? Vector2.zero())
      ..sub(bodyA?.velocity ?? Vector2.zero());

    final velAlongNormal = _relativeVelocity.dot(_normal);
    if (velAlongNormal > 0) {
      return;
    }

    final impulseMag = (-(1.0 + restitution) * velAlongNormal) / invMassSum;
    _impulse
      ..setFrom(_normal)
      ..scale(impulseMag);

    if (bodyA != null && invMassA > 0) {
      bodyA.velocity.addScaled(_impulse, -invMassA);
    }
    if (bodyB != null && invMassB > 0) {
      bodyB.velocity.addScaled(_impulse, invMassB);
    }

    _applyFriction(
      bodyA: bodyA,
      bodyB: bodyB,
      invMassA: invMassA,
      invMassB: invMassB,
      invMassSum: invMassSum,
      normalImpulseMag: impulseMag,
      staticFriction: staticFriction,
      dynamicFriction: dynamicFriction,
    );
  }

  void _applyFriction({
    required RigidBody? bodyA,
    required RigidBody? bodyB,
    required double invMassA,
    required double invMassB,
    required double invMassSum,
    required double normalImpulseMag,
    required double staticFriction,
    required double dynamicFriction,
  }) {
    _relativeVelocity
      ..setZero()
      ..add(bodyB?.velocity ?? Vector2.zero())
      ..sub(bodyA?.velocity ?? Vector2.zero());

    _tangent.setFrom(_relativeVelocity);
    _normalProjection
      ..setFrom(_normal)
      ..scale(_relativeVelocity.dot(_normal));
    _tangent.sub(_normalProjection);

    final tangentLength2 = _tangent.length2;
    if (tangentLength2 <= 1e-9) {
      return;
    }
    _tangent.scale(1.0 / math.sqrt(tangentLength2));

    final jt = -_relativeVelocity.dot(_tangent) / invMassSum;
    if (jt == 0) {
      return;
    }

    final frictionImpulseMag = jt.abs() < (normalImpulseMag * staticFriction)
        ? jt
        : -normalImpulseMag * dynamicFriction * jt.sign;

    _impulse
      ..setFrom(_tangent)
      ..scale(frictionImpulseMag);

    if (bodyA != null && invMassA > 0) {
      bodyA.velocity.addScaled(_impulse, -invMassA);
    }
    if (bodyB != null && invMassB > 0) {
      bodyB.velocity.addScaled(_impulse, invMassB);
    }
  }

  double _closingSpeed({required RigidBody? bodyA, required RigidBody? bodyB}) {
    _relativeVelocity
      ..setZero()
      ..add(bodyB?.velocity ?? Vector2.zero())
      ..sub(bodyA?.velocity ?? Vector2.zero());
    final alongNormal = _relativeVelocity.dot(_normal);
    return alongNormal < 0 ? -alongNormal : 0.0;
  }
}
