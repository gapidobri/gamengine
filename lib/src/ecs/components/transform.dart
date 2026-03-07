import 'dart:math' as math;

import 'package:gamengine/src/ecs/components/component.dart';
import 'package:vector_math/vector_math_64.dart';

class Transform extends Component {
  static const double _twoPi = math.pi * 2.0;

  Vector2 position = Vector2.zero();
  double _rotation;
  Vector2 scale = Vector2.all(1);

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

  Transform({Vector2? position, double rotation = 0, Vector2? scale})
    : position = position ?? Vector2.zero(),
      _rotation = rotation,
      scale = scale ?? Vector2.all(1);
}
