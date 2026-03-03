import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

class CameraState {
  Vector2 position = Vector2.zero();
  double zoom = 1.0;
  double cullingPadding = 128.0;

  double viewportWidth = 0;
  double viewportHeight = 0;

  Rect get worldViewRect {
    final safeZoom = zoom <= 0 ? 1.0 : zoom;
    final halfW = (viewportWidth / safeZoom) * 0.5;
    final halfH = (viewportHeight / safeZoom) * 0.5;

    return Rect.fromLTRB(
      position.x - halfW,
      position.y - halfH,
      position.x + halfW,
      position.y + halfH,
    );
  }

  Rect get worldCullRect => worldViewRect.inflate(cullingPadding);
}
