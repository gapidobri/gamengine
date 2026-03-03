import 'package:gamengine/src/ecs/components/component.dart';
import 'package:vector_math/vector_math_64.dart';

class Transform extends Component {
  Vector2 position = Vector2.zero();
  double rotation = 0;
  Vector2 scale = Vector2.all(1);

  Transform({Vector2? position, this.rotation = 0, Vector2? scale})
    : position = position ?? Vector2.zero(),
      scale = scale ?? Vector2.all(1);
}
