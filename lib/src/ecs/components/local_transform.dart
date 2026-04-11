import 'dart:math' as math;

import 'package:gamengine/gamengine.dart';

class LocalTransform extends Component {
  LocalTransform({Vector2? position, double? rotation, Vector2? scale})
    : position = position ?? Vector2.zero(),
      _rotation = rotation ?? 0,
      scale = scale ?? Vector2.all(1);

  static const double _twoPi = math.pi * 2.0;

  final Vector2 position;
  double _rotation;
  final Vector2 scale;

  double get rotation => _rotation;

  set rotation(double value) {
    if (value >= -math.pi && value <= math.pi) {
      _rotation = value;
      return;
    }

    var wrapped = value % _twoPi;
    if (wrapped <= -math.pi) {
      wrapped += _twoPi;
    } else if (wrapped > math.pi) {
      wrapped -= _twoPi;
    }

    _rotation = wrapped;
  }
}
