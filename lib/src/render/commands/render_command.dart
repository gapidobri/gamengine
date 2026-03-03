import 'dart:ui';

abstract class RenderCommand {
  RenderCommand({this.z = 0});

  final int z;

  Rect? get worldBounds => null;
}
