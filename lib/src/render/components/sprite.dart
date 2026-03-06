import 'dart:ui';

import 'package:gamengine/src/render/components/drawable.dart';

class Sprite extends Drawable {
  bool visible;
  Image? image;
  Rect? sourceRect;

  Sprite({
    this.visible = true,
    this.image,
    this.sourceRect,
    super.paint,
    super.z = 0,
  });
}
