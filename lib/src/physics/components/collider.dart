import 'package:gamengine/src/ecs/components/component.dart';

abstract class CollisionShape implements Component {
  bool get enabled;
  double get restitution;
  double get staticFriction;
  double get dynamicFriction;
}
