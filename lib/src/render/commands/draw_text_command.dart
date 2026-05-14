import 'package:flutter/painting.dart';
import 'package:gamengine/render.dart';

class DrawTextCommand extends RenderCommand {
  const DrawTextCommand({
    required this.text,
    required this.position,
    this.rotation = 0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.anchor = const Offset(0.5, 0.5),
    this.paint,
    super.z = 0,
  });

  final InlineSpan text;
  final Offset position;
  final double rotation;
  final double scaleX;
  final double scaleY;
  final Offset anchor;
  final Paint? paint;
}
