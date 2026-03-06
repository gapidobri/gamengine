import 'package:gamengine/src/physics/components/collider.dart';

class CircleCollider extends Collider {
  CircleCollider({
    required super.radius,
    super.restitution,
    super.staticFriction,
    super.dynamicFriction,
    super.enabled,
  });
}
