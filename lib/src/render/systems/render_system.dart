import 'dart:ui';

import 'package:gamengine/src/ecs/system.dart';
import 'package:gamengine/src/ecs/components/transform.dart';
import 'package:gamengine/src/ecs/world.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/commands/render_commands.dart';
import 'package:gamengine/src/render/components/circle_shape.dart';
import 'package:gamengine/src/render/components/sprite.dart';
import 'package:gamengine/src/render/systems/particle_system.dart';
import 'package:gamengine/src/render/core/render_metrics.dart';
import 'package:gamengine/src/render/core/render_queue.dart';

class RenderSystem extends System {
  final RenderQueue queue;
  final CameraState camera;
  final RenderMetrics metrics;
  final ParticleSystem? particleSystem;

  RenderSystem({
    required this.queue,
    required this.camera,
    RenderMetrics? metrics,
    this.particleSystem,
  }) : metrics = metrics ?? RenderMetrics();

  @override
  int get priority => 1000;

  @override
  void update(double dt, World world, Commands commands) {
    queue.beginFrame();
    metrics.sceneItems = 0;
    metrics.drawnItems = 0;

    final cullRect = camera.worldCullRect;
    _emitSpriteCommands(world, cullRect);
    _emitCircleCommands(world, cullRect);
    final particles = particleSystem;
    if (particles != null) {
      metrics.sceneItems += particles.aliveCount;
      metrics.drawnItems += particles.writeRenderCommands(
        queue: queue,
        cullRect: cullRect,
      );
    }

    queue.endFrame();
  }

  void _emitSpriteCommands(World world, Rect cullRect) {
    for (final entity in world.query2<Transform, Sprite>()) {
      final transform = entity.get<Transform>();
      final sprite = entity.get<Sprite>();
      final image = sprite.image;

      if (image == null) {
        continue;
      }
      metrics.sceneItems++;

      if (!sprite.visible) {
        continue;
      }

      _addIfVisible(
        DrawSpriteCommand(
          image: image,
          src: sprite.sourceRect,
          position: Offset(transform.position.x, transform.position.y),
          rotation: transform.rotation,
          scaleX: transform.scale.x,
          scaleY: transform.scale.y,
          z: sprite.z,
        ),
        cullRect,
      );
    }
  }

  void _emitCircleCommands(World world, Rect cullRect) {
    for (final entity in world.query2<Transform, CircleShape>()) {
      final transform = entity.get<Transform>();
      final circle = entity.get<CircleShape>();

      metrics.sceneItems++;

      _addIfVisible(
        DrawCircleCommand(
          center: Offset(transform.position.x, transform.position.y),
          radius: circle.radius,
          paint: circle.paint,
          z: circle.z,
        ),
        cullRect,
      );
    }
  }

  void _addIfVisible(RenderCommand command, Rect cullRect) {
    final bounds = command.worldBounds;
    if (bounds != null && !bounds.overlaps(cullRect)) {
      return;
    }
    queue.add(command);
    metrics.drawnItems++;
  }
}
