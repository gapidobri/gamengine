import 'dart:ui';

import 'package:gamengine/src/render/components/drawable.dart';

class RectangleShape extends Drawable {
  Size size;
  Offset anchor;

  RectangleShape({
    required this.size,
    this.anchor = Offset.zero,
    super.paint,
    super.z,
  });
}
