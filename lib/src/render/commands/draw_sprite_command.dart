import 'dart:math' as math;
import 'dart:ui';

import 'package:gamengine/src/render/commands/render_command.dart';

class DrawSpriteCommand extends RenderCommand {
  final Image image;
  final Rect? src;
  final Offset position;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final Offset anchor;

  DrawSpriteCommand({
    required this.image,
    required this.position,
    this.src,
    this.rotation = 0,
    this.scaleX = 0,
    this.scaleY = 0,
    this.anchor = const Offset(0.5, 0.5),
    super.z = 0,
  });

  @override
  Rect get worldBounds {
    final source =
        src ??
        Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );

    final width = source.width * scaleX.abs();
    final height = source.height * scaleY.abs();

    if (width == 0 || height == 0) {
      return Rect.fromLTWH(position.dx, position.dy, 0, 0);
    }

    final localCenterX = (0.5 - anchor.dx) * width;
    final localCenterY = (0.5 - anchor.dy) * height;

    final cosR = math.cos(rotation);
    final sinR = math.sin(rotation);

    final centerX = position.dx + (localCenterX * cosR) - (localCenterY * sinR);
    final centerY = position.dy + (localCenterX * sinR) + (localCenterY * cosR);

    final halfW = width * 0.5;
    final halfH = height * 0.5;

    final aabbHalfW = (halfW * cosR.abs()) + (halfH * sinR.abs());
    final aabbHalfH = (halfW * sinR.abs()) + (halfH * cosR.abs());

    return Rect.fromLTRB(
      centerX - aabbHalfW,
      centerY - aabbHalfH,
      centerX + aabbHalfW,
      centerY + aabbHalfH,
    );
  }
}
