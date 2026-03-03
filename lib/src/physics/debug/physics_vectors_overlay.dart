import 'dart:math';

import 'package:flutter/material.dart' hide Transform;
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/physics/components/rigid_body.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/core/render_queue.dart';
import 'package:vector_math/vector_math_64.dart';

class PhysicsVectorsOverlay extends StatelessWidget {
  final World world;
  final CameraState camera;
  final RenderQueue queue;

  const PhysicsVectorsOverlay({
    super.key,
    required this.world,
    required this.camera,
    required this.queue,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _PhysicsVectorsPainter(
          world: world,
          camera: camera,
          queue: queue,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _PhysicsVectorsPainter extends CustomPainter {
  final World world;
  final CameraState camera;
  final Paint _velocityPaint = Paint()
    ..color = const Color(0xFF00D2FF)
    ..strokeWidth = 1.5;
  final Paint _forcePaint = Paint()
    ..color = const Color(0xFFFF8A00)
    ..strokeWidth = 1.5;
  final Path _arrowHead = Path();

  _PhysicsVectorsPainter({
    required this.world,
    required this.camera,
    required RenderQueue queue,
  }) : super(repaint: queue);

  @override
  void paint(Canvas canvas, Size size) {
    camera.viewportWidth = size.width;
    camera.viewportHeight = size.height;

    final velocityScale = 1.2;
    final forceScale = 0.00012;

    for (final entity in world.query2<Transform, RigidBody>()) {
      final transform = world.get<Transform>(entity);
      final rigidBody = world.get<RigidBody>(entity);
      if (rigidBody.isStatic || !rigidBody.useGravity) {
        continue;
      }

      final position = _worldToScreen(transform.position, size);
      final velocityEnd = Offset(
        position.dx + (rigidBody.velocity.x * velocityScale * camera.zoom),
        position.dy + (rigidBody.velocity.y * velocityScale * camera.zoom),
      );
      final forceEnd = Offset(
        position.dx + (rigidBody.lastAppliedForce.x * forceScale * camera.zoom),
        position.dy + (rigidBody.lastAppliedForce.y * forceScale * camera.zoom),
      );

      _drawArrow(canvas, position, velocityEnd, _velocityPaint);
      _drawArrow(canvas, position, forceEnd, _forcePaint);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Paint paint) {
    final dx = to.dx - from.dx;
    final dy = to.dy - from.dy;
    final length2 = (dx * dx) + (dy * dy);
    if (length2 <= 1e-6) {
      return;
    }

    canvas.drawLine(from, to, paint);

    final angle = atan2(dy, dx);
    const headLength = 8.0;
    const headWidth = 4.0;

    _arrowHead
      ..reset()
      ..moveTo(0, 0)
      ..lineTo(-headLength, -headWidth)
      ..lineTo(-headLength, headWidth)
      ..close();

    canvas.save();
    canvas.translate(to.dx, to.dy);
    canvas.rotate(angle);
    canvas.drawPath(_arrowHead, paint);
    canvas.restore();
  }

  Offset _worldToScreen(Vector2 worldPosition, Size size) {
    return _worldToScreenXY(worldPosition.x, worldPosition.y, size);
  }

  Offset _worldToScreenXY(double x, double y, Size size) {
    final dx = (x - camera.position.x) * camera.zoom;
    final dy = (y - camera.position.y) * camera.zoom;
    return Offset((size.width * 0.5) + dx, (size.height * 0.5) + dy);
  }

  @override
  bool shouldRepaint(covariant _PhysicsVectorsPainter oldDelegate) {
    return oldDelegate.camera != camera || oldDelegate.world != world;
  }
}
