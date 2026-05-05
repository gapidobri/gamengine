import 'dart:ui';

import 'package:gamengine/gamengine.dart';

class Sprite extends Drawable {
  bool visible;
  Asset<Image>? image;
  Rect? sourceRect;

  Sprite({
    this.visible = true,
    this.image,
    this.sourceRect,
    super.paint,
    super.z = 0,
  });
}
