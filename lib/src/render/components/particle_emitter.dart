import 'dart:ui';

import 'package:gamengine/src/ecs/components/component.dart';
import 'package:vector_math/vector_math_64.dart';

class ParticleEmitter extends Component {
  bool enabled;
  double emissionRate;
  int burstCount;
  double spread;
  double speedMin;
  double speedMax;
  double lifetimeMin;
  double lifetimeMax;
  double sizeStartMin;
  double sizeStartMax;
  double sizeEndMin;
  double sizeEndMax;
  double drag;
  int z;
  Vector2 localOffset;
  Vector2 localDirection;
  bool alignToRotation;
  Color colorStart;
  Color colorEnd;

  double spawnRemainder = 0;

  ParticleEmitter({
    this.enabled = true,
    this.emissionRate = 0,
    this.burstCount = 0,
    this.spread = 0.4,
    this.speedMin = 10,
    this.speedMax = 30,
    this.lifetimeMin = 0.2,
    this.lifetimeMax = 0.8,
    this.sizeStartMin = 1,
    this.sizeStartMax = 2.5,
    this.sizeEndMin = 0,
    this.sizeEndMax = 1,
    this.drag = 0,
    this.z = 1,
    Vector2? localOffset,
    Vector2? localDirection,
    this.alignToRotation = true,
    this.colorStart = const Color(0xFFFFE08A),
    this.colorEnd = const Color(0x00FF6A00),
  }) : localOffset = localOffset ?? Vector2.zero(),
       localDirection = localDirection ?? Vector2(0, 1);
}
