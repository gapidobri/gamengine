import 'package:flutter/material.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/commands/render_commands.dart';
import 'package:gamengine/src/render/core/render_queue.dart';

class Painter extends CustomPainter {
  final RenderQueue queue;
  final Paint _spritePaint = Paint();
  final Paint _circlePaint = Paint();
  final List<RSTransform> _atlasTransforms = <RSTransform>[];
  final List<Rect> _atlasSources = <Rect>[];

  final CameraState camera;
  final bool useAtlasBatching;

  Painter({
    required this.queue,
    CameraState? camera,
    this.useAtlasBatching = true,
  })
    : camera = camera ?? CameraState(),
      super(repaint: queue);

  @override
  void paint(Canvas canvas, Size size) {
    camera.viewportWidth = size.width;
    camera.viewportHeight = size.height;

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(camera.zoom);
    canvas.translate(-camera.position.x, -camera.position.y);

    DrawSpriteCommand? batchSeed;

    for (final command in queue.commands) {
      switch (command) {
        case DrawSpriteCommand():
          if (useAtlasBatching && _isAtlasEligible(command)) {
            final seed = batchSeed;
            if (seed == null ||
                seed.image != command.image ||
                seed.z != command.z) {
              _flushSpriteBatch(canvas, batchSeed);
              batchSeed = command;
            }
            _pushSpriteToBatch(command);
          } else {
            _flushSpriteBatch(canvas, batchSeed);
            batchSeed = null;
            _drawSprite(canvas, command);
          }
          break;
        case DrawCircleCommand():
          _flushSpriteBatch(canvas, batchSeed);
          batchSeed = null;
          _drawCircle(canvas, command);
          break;
        default:
          _flushSpriteBatch(canvas, batchSeed);
          batchSeed = null;
          break;
      }
    }
    _flushSpriteBatch(canvas, batchSeed);

    canvas.restore();
  }

  void _drawSprite(Canvas canvas, DrawSpriteCommand cmd) {
    final src = _resolveSpriteSource(cmd);
    final w = src.width * cmd.scaleX;
    final h = src.height * cmd.scaleY;

    final ax = cmd.anchor.dx * w;
    final ay = cmd.anchor.dy * h;

    canvas.save();
    canvas.translate(cmd.position.dx, cmd.position.dy);
    canvas.rotate(cmd.rotation);

    final dst = Rect.fromLTWH(-ax, -ay, w, h);
    canvas.drawImageRect(cmd.image, src, dst, _spritePaint);

    canvas.restore();
  }

  Rect _resolveSpriteSource(DrawSpriteCommand cmd) {
    return cmd.src ??
        Rect.fromLTWH(
          0,
          0,
          cmd.image.width.toDouble(),
          cmd.image.height.toDouble(),
        );
  }

  bool _isAtlasEligible(DrawSpriteCommand cmd) {
    final sx = cmd.scaleX;
    final sy = cmd.scaleY;
    if (sx <= 0 || sy <= 0) {
      return false;
    }
    return (sx - sy).abs() < 0.0001;
  }

  void _pushSpriteToBatch(DrawSpriteCommand cmd) {
    final src = _resolveSpriteSource(cmd);
    _atlasSources.add(src);
    _atlasTransforms.add(
      RSTransform.fromComponents(
        rotation: cmd.rotation,
        scale: cmd.scaleX,
        anchorX: cmd.anchor.dx * src.width,
        anchorY: cmd.anchor.dy * src.height,
        translateX: cmd.position.dx,
        translateY: cmd.position.dy,
      ),
    );
  }

  void _flushSpriteBatch(Canvas canvas, DrawSpriteCommand? seed) {
    if (seed == null || _atlasTransforms.isEmpty) {
      _atlasTransforms.clear();
      _atlasSources.clear();
      return;
    }

    canvas.drawAtlas(
      seed.image,
      _atlasTransforms,
      _atlasSources,
      null,
      BlendMode.srcOver,
      null,
      _spritePaint,
    );
    _atlasTransforms.clear();
    _atlasSources.clear();
  }

  void _drawCircle(Canvas canvas, DrawCircleCommand cmd) {
    _circlePaint.color = cmd.color;
    canvas.drawCircle(cmd.center, cmd.radius, _circlePaint);
  }

  @override
  bool shouldRepaint(covariant Painter oldDelegate) {
    return oldDelegate.camera != camera;
  }
}
