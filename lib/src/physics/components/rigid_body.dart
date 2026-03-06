import 'package:gamengine/src/ecs/components/component.dart';
import 'package:vector_math/vector_math_64.dart';

class RigidBody extends Component {
  final Vector2 velocity;
  final Vector2 acceleration;
  final Vector2 accumulatedForce;

  double accumulatedTorque;
  double angularVelocity;
  double angularAcceleration;
  double mass;
  double momentOfInertia;
  double linearDamping;
  double angularDamping;
  double gravityScale;
  bool useGravity;
  bool isStatic;
  bool lockRotation;

  RigidBody({
    Vector2? velocity,
    this.mass = 1.0,
    this.angularVelocity = 0,
    this.angularAcceleration = 0,
    this.accumulatedTorque = 0,
    this.momentOfInertia = 0,
    this.linearDamping = 0,
    this.angularDamping = 0,
    this.gravityScale = 1.0,
    this.useGravity = true,
    this.isStatic = false,
    this.lockRotation = false,
  }) : velocity = velocity ?? Vector2.zero(),
       acceleration = Vector2.zero(),
       accumulatedForce = Vector2.zero();

  double get inverseMass {
    if (isStatic || mass <= 0) {
      return 0;
    }
    return 1.0 / mass;
  }

  double get inverseInertia {
    if (isStatic || lockRotation || momentOfInertia <= 0) {
      return 0;
    }
    return 1.0 / momentOfInertia;
  }

  void addForce(Vector2 force) {
    accumulatedForce.add(force);
  }

  void addTorque(double torque) {
    accumulatedTorque += torque;
  }
}
