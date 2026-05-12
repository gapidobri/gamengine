import 'package:gamengine/src/ecs/components/component.dart';
import 'package:gamengine/src/render/components/paint_config.dart';

class PhysicsDebugSettings extends Component {
  bool enabled;

  bool showLinearVelocity;
  bool showLinearAcceleration;
  bool showAngularVelocity;
  bool showAngularAcceleration;

  double linearVelocityScale;
  double linearAccelerationScale;

  /// Scale for angular indicators.
  ///
  /// Arrow length is computed as `abs(value) * scale * ringRadius`.
  double angularVelocityScale;
  double angularAccelerationScale;

  /// Radius of the angular velocity ring drawn around each entity.
  double angularRingRadius;

  /// Additional radius used for the angular acceleration ring.
  double angularAccelerationRingOffset;

  /// Caps the angular tangent arrow length in world units.
  double maxAngularArrowLength;

  int z;

  PaintConfig? linearVelocityPaint;
  PaintConfig? linearAccelerationPaint;
  PaintConfig? angularRingPaint;
  PaintConfig? angularVelocityPaint;
  PaintConfig? angularAccelerationPaint;

  PhysicsDebugSettings({
    this.enabled = false,
    this.showLinearVelocity = true,
    this.showLinearAcceleration = true,
    this.showAngularVelocity = true,
    this.showAngularAcceleration = true,
    this.linearVelocityScale = 1.0,
    this.linearAccelerationScale = 1.0,
    this.angularVelocityScale = 0.15,
    this.angularAccelerationScale = 0.15,
    this.angularRingRadius = 18.0,
    this.angularAccelerationRingOffset = 6.0,
    this.maxAngularArrowLength = 48.0,
    this.z = 50_000,
    this.linearVelocityPaint,
    this.linearAccelerationPaint,
    this.angularRingPaint,
    this.angularVelocityPaint,
    this.angularAccelerationPaint,
  });
}
