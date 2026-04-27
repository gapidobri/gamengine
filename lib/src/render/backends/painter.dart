import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:gamengine/src/render/camera/camera_state.dart';
import 'package:gamengine/src/render/commands/draw_rectangle_command.dart';
import 'package:gamengine/src/render/commands/render_commands.dart';
import 'package:gamengine/src/render/core/render_queue.dart';

class Painter extends CustomPainter {
  final RenderQueue queue;
  final Paint _backgroundPaint = Paint();
  final Paint _defaultPaint = Paint()..color = Color(0xFFFFFFFF);
  final Paint _spritePaint = Paint()
    ..isAntiAlias = false
    ..filterQuality = FilterQuality.none;
  final List<RSTransform> _atlasTransforms = <RSTransform>[];
  final List<Rect> _atlasSources = <Rect>[];

  final CameraState camera;
  final bool useAtlasBatching;
  final double devicePixelRatio;

  Painter({
    required this.queue,
    CameraState? camera,
    this.useAtlasBatching = true,
    this.devicePixelRatio = 1.0,
  }) : camera = camera ?? CameraState(),
       super(repaint: queue);

  @override
  void paint(Canvas canvas, Size size) {
    final hasLockedViewport =
        camera.targetViewportWidth > 0 && camera.targetViewportHeight > 0;
    final targetWidth = hasLockedViewport
        ? camera.targetViewportWidth
        : size.width;
    final targetHeight = hasLockedViewport
        ? camera.targetViewportHeight
        : size.height;

    final safeTargetWidth = targetWidth <= 0 ? 1.0 : targetWidth;
    final safeTargetHeight = targetHeight <= 0 ? 1.0 : targetHeight;

    final fitScale = math.min(
      size.width / safeTargetWidth,
      size.height / safeTargetHeight,
    );
    final viewportScale = fitScale.isFinite && fitScale > 0 ? fitScale : 1.0;

    camera.viewportWidth = size.width / viewportScale;
    camera.viewportHeight = size.height / viewportScale;
    camera.viewportScale = viewportScale;
    camera.viewportOffsetX = 0;
    camera.viewportOffsetY = 0;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      _backgroundPaint,
    );

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(viewportScale);
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
        case DrawRectangleCommand():
          _flushSpriteBatch(canvas, batchSeed);
          batchSeed = null;
          _drawRectangle(canvas, command);
          break;
        case DrawTiledSpriteCommand():
          _flushSpriteBatch(canvas, batchSeed);
          batchSeed = null;
          _drawTiledSprite(canvas, command);
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
    canvas.drawImageRect(cmd.image, src, dst, cmd.paint ?? _spritePaint);

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
    if (cmd.paint != null) {
      return false;
    }
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
    canvas.drawCircle(cmd.center, cmd.radius, cmd.paint ?? _defaultPaint);
  }

  void _drawRectangle(Canvas canvas, DrawRectangleCommand cmd) {
    final ax = cmd.anchor.dx * cmd.rect.width;
    final ay = cmd.anchor.dy * cmd.rect.height;

    canvas.save();
    canvas.translate(cmd.rect.left, cmd.rect.top);
    canvas.rotate(cmd.rotation);
    final rect = Rect.fromLTWH(-ax, -ay, cmd.rect.width, cmd.rect.height);

    canvas.drawRect(rect, cmd.paint ?? _defaultPaint);

    canvas.restore();
  }

  void _drawTiledSprite(Canvas canvas, DrawTiledSpriteCommand cmd) {
    final coverageRect = cmd.coverageRect;
    if (coverageRect != null) {
      _drawInfiniteTiledSprite(canvas, cmd, coverageRect);
      return;
    }

    final areaW = cmd.areaSize.width * cmd.scaleX.abs();
    final areaH = cmd.areaSize.height * cmd.scaleY.abs();
    final tileW = cmd.tileSize.width * cmd.scaleX.abs();
    final tileH = cmd.tileSize.height * cmd.scaleY.abs();

    if (areaW <= 0 || areaH <= 0 || tileW <= 0 || tileH <= 0) {
      return;
    }

    final ax = cmd.anchor.dx * areaW;
    final ay = cmd.anchor.dy * areaH;
    final dstRect = Rect.fromLTWH(-ax, -ay, areaW, areaH);
    final srcRect = Rect.fromLTWH(
      0,
      0,
      cmd.image.width.toDouble(),
      cmd.image.height.toDouble(),
    );

    canvas.save();
    canvas.translate(cmd.position.dx, cmd.position.dy);
    canvas.rotate(cmd.rotation);
    canvas.clipRect(dstRect);

    final paint = cmd.paint ?? _spritePaint;
    for (double x = dstRect.left; x < dstRect.right; x += tileW) {
      for (double y = dstRect.top; y < dstRect.bottom; y += tileH) {
        canvas.drawImageRect(
          cmd.image,
          srcRect,
          Rect.fromLTWH(x, y, tileW, tileH),
          paint,
        );
      }
    }

    canvas.restore();
  }

  void _drawInfiniteTiledSprite(
    Canvas canvas,
    DrawTiledSpriteCommand cmd,
    Rect coverageRect,
  ) {
    final tileW = cmd.tileSize.width * cmd.scaleX.abs();
    final tileH = cmd.tileSize.height * cmd.scaleY.abs();

    if (coverageRect.isEmpty || tileW <= 0 || tileH <= 0) {
      return;
    }

    final srcRect = Rect.fromLTWH(
      0,
      0,
      cmd.image.width.toDouble(),
      cmd.image.height.toDouble(),
    );
    final paint = cmd.paint ?? _spritePaint;
    final origin = cmd.tileOrigin ?? cmd.position;

    canvas.save();
    canvas.clipRect(coverageRect);
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(cmd.rotation);

    final localCoverage = _transformRectToLocal(
      coverageRect,
      origin,
      cmd.rotation,
    );
    final startX = _floorToTile(localCoverage.left, tileW) - tileW;
    final endX = _ceilToTile(localCoverage.right, tileW) + tileW;
    final startY = _floorToTile(localCoverage.top, tileH) - tileH;
    final endY = _ceilToTile(localCoverage.bottom, tileH) + tileH;

    for (double x = startX; x < endX; x += tileW) {
      for (double y = startY; y < endY; y += tileH) {
        canvas.drawImageRect(
          cmd.image,
          srcRect,
          Rect.fromLTWH(x, y, tileW, tileH),
          paint,
        );
      }
    }

    canvas.restore();
  }

  Rect _transformRectToLocal(Rect rect, Offset origin, double rotation) {
    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    Offset toLocal(Offset point) {
      final dx = point.dx - origin.dx;
      final dy = point.dy - origin.dy;
      return Offset((dx * cosR) + (dy * sinR), (-dx * sinR) + (dy * cosR));
    }

    final points = <Offset>[
      toLocal(rect.topLeft),
      toLocal(rect.topRight),
      toLocal(rect.bottomLeft),
      toLocal(rect.bottomRight),
    ];

    var minX = points.first.dx;
    var maxX = points.first.dx;
    var minY = points.first.dy;
    var maxY = points.first.dy;

    for (final point in points.skip(1)) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  double _floorToTile(double value, double tileSize) {
    return (value / tileSize).floorToDouble() * tileSize;
  }

  double _ceilToTile(double value, double tileSize) {
    return (value / tileSize).ceilToDouble() * tileSize;
  }

  @override
  bool shouldRepaint(covariant Painter oldDelegate) {
    return oldDelegate.camera != camera ||
        oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}
