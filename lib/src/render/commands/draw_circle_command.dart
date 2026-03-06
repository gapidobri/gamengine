import 'dart:ui';

import 'package:gamengine/src/render/commands/render_command.dart';

class DrawCircleCommand extends RenderCommand {
  final Offset center;
  final double radius;
  final Paint? paint;

  DrawCircleCommand({
    required this.center,
    required this.radius,
    this.paint,
    super.z = 0,
  });

  @override
  Rect get worldBounds {
    return Rect.fromCircle(center: center, radius: radius.abs());
  }
}
