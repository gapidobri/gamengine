part of 'collision_system.dart';

extension _CollisionResolutionExt on CollisionSystem {
  static const double _restitutionVelocityThreshold = 0.5;
  static const double _frictionImpulseThreshold = 1e-6;

  void _resolvePosition({
    required Transform transformA,
    required RigidBody? bodyA,
    required Transform transformB,
    required RigidBody? bodyB,
    required Vector2 normal,
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
    transformA.position.addScaled(normal, -correctionMag * invMassA);
    transformB.position.addScaled(normal, correctionMag * invMassB);
  }

  void _resolveVelocity({
    required Transform transformA,
    required RigidBody? bodyA,
    required CollisionShape colliderA,
    required Vector2 contactPointA,
    required Transform transformB,
    required RigidBody? bodyB,
    required CollisionShape colliderB,
    required Vector2 contactPointB,
    required Vector2 normal,
    required double restitution,
    required double staticFriction,
    required double dynamicFriction,
  }) {
    final invMassA = bodyA?.inverseMass ?? 0.0;
    final invMassB = bodyB?.inverseMass ?? 0.0;
    final invInertiaA = _inverseInertia(bodyA, colliderA);
    final invInertiaB = _inverseInertia(bodyB, colliderB);
    if ((invMassA + invMassB + invInertiaA + invInertiaB) <= 0) {
      return;
    }

    _contactOffsetA
      ..setFrom(contactPointA)
      ..sub(transformA.position);
    _contactOffsetB
      ..setFrom(contactPointB)
      ..sub(transformB.position);
    _setContactVelocity(
      body: bodyA,
      contactOffset: _contactOffsetA,
      out: _velocityA,
    );
    _setContactVelocity(
      body: bodyB,
      contactOffset: _contactOffsetB,
      out: _velocityB,
    );
    _relativeVelocity
      ..setFrom(_velocityB)
      ..sub(_velocityA);
    final velAlongNormal = _relativeVelocity.dot(normal);
    if (velAlongNormal > 0) {
      return;
    }

    final raCrossN = _cross2(_contactOffsetA, normal);
    final rbCrossN = _cross2(_contactOffsetB, normal);
    final impulseDenominator =
        invMassA +
        invMassB +
        (raCrossN * raCrossN * invInertiaA) +
        (rbCrossN * rbCrossN * invInertiaB);
    if (impulseDenominator <= 0) {
      return;
    }

    final effectiveRestitution =
        velAlongNormal.abs() < _restitutionVelocityThreshold
        ? 0.0
        : restitution;
    final impulseMag =
        (-(1.0 + effectiveRestitution) * velAlongNormal) / impulseDenominator;
    _impulse
      ..setFrom(normal)
      ..scale(impulseMag);

    if (bodyA != null && invMassA > 0) {
      bodyA.velocity.addScaled(_impulse, -invMassA);
    }
    if (bodyB != null && invMassB > 0) {
      bodyB.velocity.addScaled(_impulse, invMassB);
    }
    if (bodyA != null && invInertiaA > 0) {
      bodyA.angularVelocity -= raCrossN * impulseMag * invInertiaA;
    }
    if (bodyB != null && invInertiaB > 0) {
      bodyB.angularVelocity += rbCrossN * impulseMag * invInertiaB;
    }

    _applyFriction(
      bodyA: bodyA,
      invInertiaA: invInertiaA,
      contactOffsetA: _contactOffsetA,
      bodyB: bodyB,
      invInertiaB: invInertiaB,
      contactOffsetB: _contactOffsetB,
      normal: normal,
      invMassA: invMassA,
      invMassB: invMassB,
      normalImpulseMag: impulseMag,
      staticFriction: staticFriction,
      dynamicFriction: dynamicFriction,
    );
  }

  void _applyFriction({
    required RigidBody? bodyA,
    required double invInertiaA,
    required Vector2 contactOffsetA,
    required RigidBody? bodyB,
    required double invInertiaB,
    required Vector2 contactOffsetB,
    required Vector2 normal,
    required double invMassA,
    required double invMassB,
    required double normalImpulseMag,
    required double staticFriction,
    required double dynamicFriction,
  }) {
    if (normalImpulseMag.abs() <= _frictionImpulseThreshold) {
      return;
    }

    _setContactVelocity(
      body: bodyA,
      contactOffset: contactOffsetA,
      out: _velocityA,
    );
    _setContactVelocity(
      body: bodyB,
      contactOffset: contactOffsetB,
      out: _velocityB,
    );
    _relativeVelocity
      ..setFrom(_velocityB)
      ..sub(_velocityA);

    _tangent.setFrom(_relativeVelocity);
    _normalProjection
      ..setFrom(normal)
      ..scale(_relativeVelocity.dot(normal));
    _tangent.sub(_normalProjection);

    final tangentLength2 = _tangent.length2;
    if (tangentLength2 <= 1e-9) {
      return;
    }
    _tangent.scale(1.0 / math.sqrt(tangentLength2));

    final raCrossT = _cross2(contactOffsetA, _tangent);
    final rbCrossT = _cross2(contactOffsetB, _tangent);
    final frictionDenominator =
        invMassA +
        invMassB +
        (raCrossT * raCrossT * invInertiaA) +
        (rbCrossT * rbCrossT * invInertiaB);
    if (frictionDenominator <= 0) {
      return;
    }

    final jt = -_relativeVelocity.dot(_tangent) / frictionDenominator;
    if (jt.abs() <= _frictionImpulseThreshold) {
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
    if (bodyA != null && invInertiaA > 0) {
      bodyA.angularVelocity -= raCrossT * frictionImpulseMag * invInertiaA;
    }
    if (bodyB != null && invInertiaB > 0) {
      bodyB.angularVelocity += rbCrossT * frictionImpulseMag * invInertiaB;
    }
  }

  double _closingSpeed({
    required Transform transformA,
    required RigidBody? bodyA,
    required Vector2 contactPointA,
    required Transform transformB,
    required RigidBody? bodyB,
    required Vector2 contactPointB,
    required Vector2 normal,
  }) {
    _contactOffsetA
      ..setFrom(contactPointA)
      ..sub(transformA.position);
    _contactOffsetB
      ..setFrom(contactPointB)
      ..sub(transformB.position);
    _setContactVelocity(
      body: bodyA,
      contactOffset: _contactOffsetA,
      out: _velocityA,
    );
    _setContactVelocity(
      body: bodyB,
      contactOffset: _contactOffsetB,
      out: _velocityB,
    );
    _relativeVelocity
      ..setFrom(_velocityB)
      ..sub(_velocityA);
    final alongNormal = _relativeVelocity.dot(normal);
    return alongNormal < 0 ? -alongNormal : 0.0;
  }

  void _setContactVelocity({
    required RigidBody? body,
    required Vector2 contactOffset,
    required Vector2 out,
  }) {
    if (body == null) {
      out.setZero();
      return;
    }

    out
      ..setFrom(body.velocity)
      ..x += -body.angularVelocity * contactOffset.y
      ..y += body.angularVelocity * contactOffset.x;
  }

  double _cross2(Vector2 a, Vector2 b) {
    return (a.x * b.y) - (a.y * b.x);
  }

  double _inverseInertia(RigidBody? body, CollisionShape collider) {
    if (body == null) {
      return 0;
    }
    if (body.isStatic || body.lockRotation) {
      return 0;
    }
    if (body.momentOfInertia > 0) {
      return body.inverseInertia;
    }

    final mass = body.mass;
    if (mass <= 0) {
      return 0;
    }

    if (collider is RectangleCollider) {
      final width = collider.halfWidth * 2;
      final height = collider.halfHeight * 2;
      final inertia = (mass * ((width * width) + (height * height))) / 12;
      return inertia > 0 ? 1.0 / inertia : 0;
    }
    if (collider is CircleCollider) {
      final inertia = 0.5 * mass * collider.radius * collider.radius;
      return inertia > 0 ? 1.0 / inertia : 0;
    }
    return 0;
  }
}
