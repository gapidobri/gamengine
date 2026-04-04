import 'dart:ui';

import 'package:gamengine/gamengine.dart';

class DrawRectangleCommand extends RenderCommand {
  final Rect rect;
  final double rotation;
  final Offset anchor;
  final Paint? paint;

  DrawRectangleCommand({
    required this.rect,
    this.rotation = 0,
    this.anchor = Offset.zero,
    this.paint,
    super.z = 0,
  });

  @override
  Rect get worldBounds => rect;
}
