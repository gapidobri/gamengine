import 'dart:ui';

abstract class RenderCommand {
  const RenderCommand({this.z = 0});

  final int z;

  Rect? get worldBounds => null;
}
