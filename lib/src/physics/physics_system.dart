import 'dart:math' as math;

import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/physics/components/gravity_source.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:vector_math/vector_math_64.dart';

class PhysicsSystem extends System {
  static const double universalGravitationalConstant = 6.67430e-11;

  final double gravitationalConstant;
  final Vector2 globalGravity;
  final double maxDeltaTime;

  final Vector2 _delta = Vector2.zero();
  final Vector2 _gravityAcc = Vector2.zero();
  final Vector2 _tmp = Vector2.zero();

  PhysicsSystem({
    this.gravitationalConstant = universalGravitationalConstant,
    Vector2? globalGravity,
    this.maxDeltaTime = 1 / 30,
  }) : globalGravity = globalGravity ?? Vector2.zero();

  @override
  int get priority => 500;

  @override
  void update(double dt, World world, Commands commands) {
    if (dt <= 0) {
      return;
    }

    var remaining = dt;
    while (remaining > 0) {
      final step = remaining > maxDeltaTime ? maxDeltaTime : remaining;
      _integrateStep(world, step);
      remaining -= step;
    }
  }

  void _integrateStep(World world, double step) {
    final gravitySources = world.query2<Transform, GravitySource>().toList(
      growable: false,
    );

    for (final entity in world.query2<Transform, RigidBody>()) {
      final transform = entity.get<Transform>();
      final rigidBody = entity.get<RigidBody>();

      if (rigidBody.isStatic) {
        rigidBody.acceleration.setZero();
        rigidBody.accumulatedForce.setZero();
        rigidBody.accumulatedTorque = 0;
        continue;
      }

      final invMass = rigidBody.inverseMass;
      rigidBody.acceleration
        ..setFrom(globalGravity)
        ..scale(rigidBody.useGravity ? rigidBody.gravityScale : 0);

      if (rigidBody.useGravity) {
        _accumulateSourceGravity(
          position: transform.position,
          gravitySources: gravitySources,
          out: _gravityAcc,
        );
        rigidBody.acceleration.add(_gravityAcc);
      }

      if (invMass > 0) {
        _tmp
          ..setFrom(rigidBody.accumulatedForce)
          ..scale(invMass);
        rigidBody.acceleration.add(_tmp);
      }

      rigidBody.velocity.addScaled(rigidBody.acceleration, step);

      final invInertia = rigidBody.inverseInertia;
      final angularAccelerationFromTorque = invInertia > 0
          ? rigidBody.accumulatedTorque * invInertia
          : 0.0;
      final totalAngularAcceleration =
          rigidBody.angularAcceleration + angularAccelerationFromTorque;
      rigidBody.angularVelocity += totalAngularAcceleration * step;

      if (rigidBody.linearDamping > 0) {
        final damping = math.max(0.0, 1.0 - (rigidBody.linearDamping * step));
        rigidBody.velocity.scale(damping);
      }

      transform.position.addScaled(rigidBody.velocity, step);
      transform.rotation += rigidBody.angularVelocity * step;

      if (rigidBody.angularDamping > 0) {
        final damping = math.max(0.0, 1.0 - (rigidBody.angularDamping * step));
        rigidBody.angularVelocity *= damping;
      }

      rigidBody.accumulatedForce.setZero();
      rigidBody.accumulatedTorque = 0;
    }
  }

  void _accumulateSourceGravity({
    required Vector2 position,
    required List<Entity> gravitySources,
    required Vector2 out,
  }) {
    out.setZero();

    for (final sourceEntity in gravitySources) {
      final sourceTransform = sourceEntity.get<Transform>();
      final source = sourceEntity.get<GravitySource>();
      if (!source.enabled || source.mass <= 0) {
        continue;
      }

      _delta
        ..setFrom(sourceTransform.position)
        ..sub(position);

      final distance2 = _delta.length2;
      if (distance2 == 0) {
        continue;
      }

      final minDistance = source.minDistance <= 0 ? 1.0 : source.minDistance;
      final minDistance2 = minDistance * minDistance;
      final safeDistance2 = distance2 < minDistance2 ? minDistance2 : distance2;

      final invDistance = 1.0 / math.sqrt(safeDistance2);
      _delta.scale(invDistance);

      final magnitude = gravitationalConstant * source.mass / safeDistance2;
      out.addScaled(_delta, magnitude);
    }
  }
}
