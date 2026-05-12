import 'dart:math' as math;
import 'dart:ui';

import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/extensions/vector2.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/physics/debug/physics_debug_override.dart';
import 'package:gamengine/src/physics/debug/physics_debug_settings.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/commands/draw_circle_command.dart';
import 'package:gamengine/src/render/commands/draw_line_command.dart';
import 'package:gamengine/src/render/core/render_queue.dart';
import 'package:gamengine/src/render/systems/render_pass.dart';

class PhysicsVectorsOverlay extends RenderPass {
  @override
  int get priority => 0;

  @override
  RenderPassStage get stage => RenderPassStage.afterWorld;

  @override
  void write(
    World world, {
    required CameraState camera,
    required RenderQueue queue,
  }) {
    final globalSettings = world.tryGetComponent<PhysicsDebugSettings>();
    final globalEnabled = globalSettings?.enabled ?? false;
    PhysicsDebugSettings? fallbackSettings;

    for (final entity in world.query2<Transform, RigidBody>()) {
      final override = entity.tryGet<PhysicsDebugOverride>();
      final enabled = override?.enabled ?? globalEnabled;
      if (!enabled) {
        continue;
      }

      final settings =
          globalSettings ??
          (fallbackSettings ??= PhysicsDebugSettings(enabled: true));

      final z = settings.z;

      final velocityPaint = settings.linearVelocityPaint?.toPaint();
      final accelerationPaint = settings.linearAccelerationPaint?.toPaint();
      final angularRingPaint = settings.angularRingPaint?.toPaint();
      final angularVelocityPaint = settings.angularVelocityPaint?.toPaint();
      final angularAccelerationPaint = settings.angularAccelerationPaint
          ?.toPaint();

      final ringRadius = settings.angularRingRadius;
      final accelRingRadius =
          ringRadius + settings.angularAccelerationRingOffset;

      final transform = entity.get<Transform>();
      final body = entity.get<RigidBody>();

      final center = transform.position.toOffset();

      if (settings.showLinearVelocity) {
        final vx = body.velocity.x * settings.linearVelocityScale;
        final vy = body.velocity.y * settings.linearVelocityScale;
        if (vx != 0 || vy != 0) {
          queue.add(
            DrawLineCommand(
              a: center,
              b: Offset(center.dx + vx, center.dy + vy),
              paint: velocityPaint,
              z: z,
            ),
          );
        }
      }

      if (settings.showLinearAcceleration) {
        final ax = body.acceleration.x * settings.linearAccelerationScale;
        final ay = body.acceleration.y * settings.linearAccelerationScale;
        if (ax != 0 || ay != 0) {
          queue.add(
            DrawLineCommand(
              a: center,
              b: Offset(center.dx + ax, center.dy + ay),
              paint: accelerationPaint,
              z: z,
            ),
          );
        }
      }

      final omega = body.angularVelocity;
      final alpha = body.computedAngularAcceleration;

      final showAnyAngular =
          (settings.showAngularVelocity && omega != 0) ||
          (settings.showAngularAcceleration && alpha != 0);

      if (!showAnyAngular) {
        continue;
      }

      if (angularRingPaint != null) {
        if (settings.showAngularVelocity && omega != 0) {
          queue.add(
            DrawCircleCommand(
              center: center,
              radius: ringRadius,
              paint: angularRingPaint,
              z: z,
            ),
          );
        }
        if (settings.showAngularAcceleration && alpha != 0) {
          queue.add(
            DrawCircleCommand(
              center: center,
              radius: accelRingRadius,
              paint: angularRingPaint,
              z: z,
            ),
          );
        }
      }

      // Tangent arrow at the ring's +X point.
      // In Flutter's coordinate system (Y down), positive rotation is clockwise.
      final anchorVel = Offset(center.dx + ringRadius, center.dy);
      final anchorAcc = Offset(center.dx + accelRingRadius, center.dy);

      if (settings.showAngularVelocity && omega != 0) {
        final sign = omega.sign;
        final len = math.min(
          settings.maxAngularArrowLength,
          omega.abs() * settings.angularVelocityScale * ringRadius,
        );
        if (len > 0 && sign != 0) {
          queue.add(
            DrawLineCommand(
              a: anchorVel,
              b: Offset(anchorVel.dx, anchorVel.dy + (len * sign)),
              paint: angularVelocityPaint,
              z: z,
            ),
          );
        }
      }

      if (settings.showAngularAcceleration && alpha != 0) {
        final sign = alpha.sign;
        final len = math.min(
          settings.maxAngularArrowLength,
          alpha.abs() * settings.angularAccelerationScale * accelRingRadius,
        );
        if (len > 0 && sign != 0) {
          queue.add(
            DrawLineCommand(
              a: anchorAcc,
              b: Offset(anchorAcc.dx, anchorAcc.dy + (len * sign)),
              paint: angularAccelerationPaint,
              z: z,
            ),
          );
        }
      }
    }
  }
}
