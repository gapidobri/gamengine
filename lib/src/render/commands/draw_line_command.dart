import 'dart:ui';

import 'package:gamengine/src/render/commands/render_command.dart';

class DrawLineCommand extends RenderCommand {
  final Offset a;
  final Offset b;
  final Paint? paint;

  DrawLineCommand({required this.a, required this.b, this.paint, super.z = 0});

  @override
  Rect get worldBounds {
    final rect = Rect.fromPoints(a, b);
    final strokeWidth = paint?.strokeWidth;
    if (strokeWidth == null || !strokeWidth.isFinite || strokeWidth <= 0) {
      return rect;
    }
    return rect.inflate(strokeWidth);
  }
}
