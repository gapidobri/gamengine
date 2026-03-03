import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/events/event.dart';
import 'package:vector_math/vector_math_64.dart';

class CollisionEvent extends GameEvent {
  final Entity entityA;
  final Entity entityB;
  final Vector2 point;
  final Vector2 normal;
  final double relativeSpeed;
  final double penetration;

  CollisionEvent({
    required this.entityA,
    required this.entityB,
    required this.point,
    required this.normal,
    required this.relativeSpeed,
    required this.penetration,
  });
}
