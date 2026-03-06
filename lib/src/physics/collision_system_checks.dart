part of 'collision_system.dart';

extension _CollisionCheckExt on CollisionSystem {
  bool _checkCircleCircle({
    required Transform transformA,
    required Collider colliderA,
    required Transform transformB,
    required Collider colliderB,
    required CollisionManifold manifold,
  }) {
    if (colliderA.radius <= 0 || colliderB.radius <= 0) {
      return false;
    }

    manifold.normal
      ..setFrom(transformB.position)
      ..sub(transformA.position);

    final dist2 = manifold.normal.length2;
    final radiusSum = colliderA.radius + colliderB.radius;
    final radiusSum2 = radiusSum * radiusSum;
    if (dist2 >= radiusSum2) {
      return false;
    }

    final distance = dist2 == 0 ? 0.0 : math.sqrt(dist2);
    if (distance > 0) {
      manifold.normal.scale(1.0 / distance);
    } else {
      manifold.normal
        ..x = 1
        ..y = 0;
    }

    manifold.penetration = radiusSum - distance;
    manifold.contactPoint
      ..setFrom(manifold.normal)
      ..scale(colliderA.radius)
      ..add(transformA.position);

    return true;
  }

  bool _checkRectangleRectangle({
    required Transform transformA,
    required RectangleCollider colliderA,
    required Transform transformB,
    required RectangleCollider colliderB,
    required CollisionManifold manifold,
  }) {
    if (colliderA.halfWidth <= 0 ||
        colliderA.halfHeight <= 0 ||
        colliderB.halfWidth <= 0 ||
        colliderB.halfHeight <= 0) {
      return false;
    }

    final axisA0 = _axisFromRotation(transformA.rotation);
    final axisA1 = Vector2(-axisA0.y, axisA0.x);
    final axisB0 = _axisFromRotation(transformB.rotation);
    final axisB1 = Vector2(-axisB0.y, axisB0.x);

    final centerDelta = Vector2.copy(transformB.position)
      ..sub(transformA.position);
    final axes = <Vector2>[axisA0, axisA1, axisB0, axisB1];

    var minOverlap = double.infinity;
    final bestAxis = Vector2.zero();

    for (final axis in axes) {
      final overlap = _axisOverlap(
        axis: axis,
        centerDelta: centerDelta,
        halfWidthA: colliderA.halfWidth,
        halfHeightA: colliderA.halfHeight,
        axisA0: axisA0,
        axisA1: axisA1,
        halfWidthB: colliderB.halfWidth,
        halfHeightB: colliderB.halfHeight,
        axisB0: axisB0,
        axisB1: axisB1,
      );
      if (overlap <= 0) {
        return false;
      }
      if (overlap < minOverlap) {
        minOverlap = overlap;
        bestAxis.setFrom(axis);
      }
    }

    if (centerDelta.dot(bestAxis) < 0) {
      bestAxis.scale(-1);
    }

    manifold.normal.setFrom(bestAxis);
    manifold.penetration = minOverlap;

    final supportA = _supportVertex(
      center: transformA.position,
      axis0: axisA0,
      axis1: axisA1,
      halfWidth: colliderA.halfWidth,
      halfHeight: colliderA.halfHeight,
      direction: bestAxis,
    );
    final supportB = _supportVertex(
      center: transformB.position,
      axis0: axisB0,
      axis1: axisB1,
      halfWidth: colliderB.halfWidth,
      halfHeight: colliderB.halfHeight,
      direction: Vector2.copy(bestAxis)..scale(-1),
    );

    manifold.contactPoint
      ..setFrom(supportA)
      ..add(supportB)
      ..scale(0.5);

    return true;
  }

  bool _checkRectangleCircle({
    required Transform transformA,
    required RectangleCollider colliderA,
    required Transform transformB,
    required Collider colliderB,
    required CollisionManifold manifold,
  }) {
    if (colliderA.halfWidth <= 0 ||
        colliderA.halfHeight <= 0 ||
        colliderB.radius <= 0) {
      return false;
    }

    final rectCenter = transformA.position;
    final circleCenter = transformB.position;
    final axis0 = _axisFromRotation(transformA.rotation);
    final axis1 = Vector2(-axis0.y, axis0.x);

    final centerToCircle = Vector2.copy(circleCenter)..sub(rectCenter);
    final localCircleX = centerToCircle.dot(axis0);
    final localCircleY = centerToCircle.dot(axis1);

    final localClosestX = _clamp(
      localCircleX,
      -colliderA.halfWidth,
      colliderA.halfWidth,
    );
    final localClosestY = _clamp(
      localCircleY,
      -colliderA.halfHeight,
      colliderA.halfHeight,
    );

    var localNormalX = localCircleX - localClosestX;
    var localNormalY = localCircleY - localClosestY;

    final dist2 = (localNormalX * localNormalX) + (localNormalY * localNormalY);
    final radius = colliderB.radius;
    final radius2 = radius * radius;
    if (dist2 > radius2) {
      return false;
    }

    final localContact = Vector2(localClosestX, localClosestY);

    if (dist2 > 1e-12) {
      final distance = math.sqrt(dist2);
      localNormalX /= distance;
      localNormalY /= distance;
      manifold.penetration = radius - distance;
    } else {
      final distToLeft = localCircleX + colliderA.halfWidth;
      final distToRight = colliderA.halfWidth - localCircleX;
      final distToBottom = localCircleY + colliderA.halfHeight;
      final distToTop = colliderA.halfHeight - localCircleY;

      var minDistance = distToLeft;
      localNormalX = -1;
      localNormalY = 0;

      if (distToRight < minDistance) {
        minDistance = distToRight;
        localNormalX = 1;
        localNormalY = 0;
      }
      if (distToBottom < minDistance) {
        minDistance = distToBottom;
        localNormalX = 0;
        localNormalY = -1;
      }
      if (distToTop < minDistance) {
        minDistance = distToTop;
        localNormalX = 0;
        localNormalY = 1;
      }

      manifold.penetration = radius + minDistance;
      if (localNormalX != 0) {
        localContact
          ..x = localNormalX > 0 ? colliderA.halfWidth : -colliderA.halfWidth
          ..y = _clamp(
            localCircleY,
            -colliderA.halfHeight,
            colliderA.halfHeight,
          );
      } else {
        localContact
          ..x = _clamp(localCircleX, -colliderA.halfWidth, colliderA.halfWidth)
          ..y = localNormalY > 0 ? colliderA.halfHeight : -colliderA.halfHeight;
      }
    }

    manifold.normal
      ..setFrom(axis0)
      ..scale(localNormalX)
      ..addScaled(axis1, localNormalY);

    final rectContact = Vector2.copy(rectCenter)
      ..addScaled(axis0, localContact.x)
      ..addScaled(axis1, localContact.y);
    final circleContact = Vector2.copy(circleCenter)
      ..addScaled(manifold.normal, -radius);

    manifold.contactPoint
      ..setFrom(rectContact)
      ..add(circleContact)
      ..scale(0.5);

    return true;
  }

  double _clamp(double value, double min, double max) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }

  Vector2 _axisFromRotation(double angle) {
    return Vector2(math.cos(angle), math.sin(angle));
  }

  double _axisOverlap({
    required Vector2 axis,
    required Vector2 centerDelta,
    required double halfWidthA,
    required double halfHeightA,
    required Vector2 axisA0,
    required Vector2 axisA1,
    required double halfWidthB,
    required double halfHeightB,
    required Vector2 axisB0,
    required Vector2 axisB1,
  }) {
    final projDistance = centerDelta.dot(axis).abs();
    final projA =
        (halfWidthA * axis.dot(axisA0).abs()) +
        (halfHeightA * axis.dot(axisA1).abs());
    final projB =
        (halfWidthB * axis.dot(axisB0).abs()) +
        (halfHeightB * axis.dot(axisB1).abs());
    return (projA + projB) - projDistance;
  }

  Vector2 _supportVertex({
    required Vector2 center,
    required Vector2 axis0,
    required Vector2 axis1,
    required double halfWidth,
    required double halfHeight,
    required Vector2 direction,
  }) {
    final sx = direction.dot(axis0) >= 0 ? 1.0 : -1.0;
    final sy = direction.dot(axis1) >= 0 ? 1.0 : -1.0;
    return Vector2.copy(center)
      ..addScaled(axis0, halfWidth * sx)
      ..addScaled(axis1, halfHeight * sy);
  }
}
