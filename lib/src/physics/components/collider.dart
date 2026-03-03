import 'package:gamengine/src/ecs/components/component.dart';

class Collider extends Component {
  double radius;
  double restitution;
  double staticFriction;
  double dynamicFriction;
  bool enabled;

  Collider({
    required this.radius,
    this.restitution = 0.4,
    this.staticFriction = 0.6,
    this.dynamicFriction = 0.45,
    this.enabled = true,
  });
}
