import 'package:gamengine/src/ecs/components/component.dart';
import 'package:vector_math/vector_math_64.dart';

class RigidBody extends Component {
  final Vector2 velocity;
  final Vector2 acceleration;
  final Vector2 accumulatedForce;
  final Vector2 lastAppliedForce;
  double mass;
  double angularVelocity;
  double linearDamping;
  double angularDamping;
  double gravityScale;
  bool useGravity;
  bool isStatic;

  RigidBody({
    Vector2? velocity,
    this.mass = 1.0,
    this.angularVelocity = 0,
    this.linearDamping = 0,
    this.angularDamping = 0,
    this.gravityScale = 1.0,
    this.useGravity = true,
    this.isStatic = false,
  }) : velocity = velocity ?? Vector2.zero(),
       acceleration = Vector2.zero(),
       accumulatedForce = Vector2.zero(),
       lastAppliedForce = Vector2.zero();

  double get inverseMass {
    if (isStatic || mass <= 0) {
      return 0;
    }
    return 1.0 / mass;
  }

  void addForce(Vector2 force) {
    accumulatedForce.add(force);
  }
}
