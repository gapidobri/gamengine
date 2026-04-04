import 'dart:ui';

import 'package:gamengine/gamengine.dart';
import 'package:gamengine/src/extensions/vector2.dart';
import 'package:gamengine/src/render/commands/draw_rectangle_command.dart';
import 'package:gamengine/src/render/components/rectangle_shape.dart';

class RenderSystem extends System {
  final RenderQueue queue;
  final CameraState camera;
  final RenderMetrics metrics;
  final ParticleSystem? particleSystem;
  final List<RenderPass> _passes;

  RenderSystem({
    required this.queue,
    required this.camera,
    List<RenderPass>? passes,
    RenderMetrics? metrics,
    this.particleSystem,
  }) : metrics = metrics ?? RenderMetrics(),
       _passes = [...?passes] {
    _sortPasses();
  }

  @override
  int get priority => 1000;

  List<RenderPass> get passes => List.unmodifiable(_passes);

  void addPass(RenderPass pass) {
    _passes.add(pass);
    _sortPasses();
  }

  bool removePass(RenderPass pass) {
    return _passes.remove(pass);
  }

  @override
  void update(double dt, World world, Commands commands) {
    queue.beginFrame();
    metrics.sceneItems = 0;
    metrics.drawnItems = 0;

    _writePasses(world, RenderPassStage.beforeWorld);

    final cullRect = camera.worldCullRect;
    _emitSpriteCommands(world, cullRect);
    _emitTiledSpriteCommands(world, cullRect);
    _emitCircleCommands(world, cullRect);
    _emitRectangleCommands(world, cullRect);
    final particles = particleSystem;
    if (particles != null) {
      metrics.sceneItems += particles.aliveCount;
      metrics.drawnItems += particles.writeRenderCommands(
        queue: queue,
        cullRect: cullRect,
      );
    }

    _writePasses(world, RenderPassStage.afterWorld);

    queue.endFrame();
  }

  void _writePasses(World world, RenderPassStage stage) {
    for (final pass in _passes) {
      if (pass.stage != stage) {
        continue;
      }
      pass.write(world, camera: camera, queue: queue);
    }
  }

  void _sortPasses() {
    _passes.sort((a, b) {
      final byStage = a.stage.index.compareTo(b.stage.index);
      if (byStage != 0) {
        return byStage;
      }
      return a.priority.compareTo(b.priority);
    });
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

  void _emitRectangleCommands(World world, Rect cullRect) {
    for (final entity in world.query2<Transform, RectangleShape>()) {
      final transform = entity.get<Transform>();
      final rectangle = entity.get<RectangleShape>();

      metrics.sceneItems++;

      _addIfVisible(
        DrawRectangleCommand(
          rect: transform.position.toOffset() & rectangle.size,
          anchor: rectangle.anchor,
          paint: rectangle.paint,
          z: rectangle.z,
        ),
        cullRect,
      );
    }
  }

  void _emitTiledSpriteCommands(World world, Rect cullRect) {
    for (final entity in world.query2<Transform, TiledSprite>()) {
      final transform = entity.get<Transform>();
      final sprite = entity.get<TiledSprite>();

      metrics.sceneItems++;

      if (!sprite.visible) {
        continue;
      }

      _addIfVisible(
        DrawTiledSpriteCommand(
          image: sprite.image,
          tileSize: sprite.tileSize,
          areaSize: sprite.areaSize,
          position: Offset(transform.position.x, transform.position.y),
          rotation: transform.rotation,
          scaleX: transform.scale.x,
          scaleY: transform.scale.y,
          anchor: sprite.anchor,
          paint: sprite.paint,
          z: sprite.z,
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
