import 'package:gamengine/src/physics/components/collider.dart';

class CircleCollider extends CollisionShape {
  static const int defaultCollisionLayer = 0x00000001;
  static const int defaultCollisionMask = 0x7fffffff;

  double radius;
  @override
  int collisionLayer;
  @override
  int collisionMask;
  @override
  double restitution;
  @override
  double staticFriction;
  @override
  double dynamicFriction;
  @override
  bool enabled;

  CircleCollider({
    required this.radius,
    this.collisionLayer = defaultCollisionLayer,
    this.collisionMask = defaultCollisionMask,
    this.restitution = 0.4,
    this.staticFriction = 0.6,
    this.dynamicFriction = 0.45,
    this.enabled = true,
  });
}
