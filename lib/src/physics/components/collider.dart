import 'package:gamengine/src/ecs/components/component.dart';

abstract class CollisionShape extends Component {
  bool get enabled;
  int get collisionLayer;
  int get collisionMask;
  double get restitution;
  double get staticFriction;
  double get dynamicFriction;
}

extension CollisionShapeFiltering on CollisionShape {
  bool canCollideWith(CollisionShape other) {
    final matchesMyMask = (collisionMask & other.collisionLayer) != 0;
    final matchesOtherMask = (other.collisionMask & collisionLayer) != 0;
    return matchesMyMask && matchesOtherMask;
  }
}
