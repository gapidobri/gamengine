import 'dart:math' as math;

import 'package:gamengine/src/ecs/entity.dart';
import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';

class CameraFollowSystem extends System {
  final CameraState camera;
  final Entity target;
  final double smoothing;
  final double offsetX;
  final double offsetY;

  CameraFollowSystem({
    required this.camera,
    required this.target,
    this.smoothing = 8.0,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  @override
  int get priority => 650;

  @override
  void update(double dt) {
    final targetTransform = target.get<Transform>();
    if (targetTransform == null) {
      return;
    }

    final t = dt <= 0 ? 1.0 : (1.0 - math.exp(-smoothing * dt));
    final targetX = targetTransform.position.x + offsetX;
    final targetY = targetTransform.position.y + offsetY;

    camera.position.x += (targetX - camera.position.x) * t;
    camera.position.y += (targetY - camera.position.y) * t;
  }
}
