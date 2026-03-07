import 'package:gamengine/src/ecs/components/component.dart';
import 'package:gamengine/src/physics/components/collider.dart';

class CircleCollider extends Component implements CollisionShape {
  double radius;
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
    this.restitution = 0.4,
    this.staticFriction = 0.6,
    this.dynamicFriction = 0.45,
    this.enabled = true,
  });
}
