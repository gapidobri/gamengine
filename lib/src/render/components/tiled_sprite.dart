import 'dart:ui';

import 'package:gamengine/src/render/components/drawable.dart';

class TiledSprite extends Drawable {
  TiledSprite({
    required this.image,
    required this.tileSize,
    this.areaSize = Size.zero,
    this.extendInfinitely = false,
    this.visible = true,
    this.anchor = const Offset(0.5, 0.5),
    super.paint,
    super.z = 0,
  });

  Image image;
  Size tileSize;
  Size areaSize;
  bool extendInfinitely;
  bool visible;
  Offset anchor;
}
