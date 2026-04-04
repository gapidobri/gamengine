import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

extension Vector2Extension on Vector2 {
  Offset toOffset() => Offset(x, y);
  Size toSize() => Size(x, y);
  Rect toRect() => Rect.fromLTWH(0, 0, x, y);
}
