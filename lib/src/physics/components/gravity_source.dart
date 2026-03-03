import 'package:gamengine/src/ecs/components/component.dart';

class GravitySource extends Component {
  double mass;
  double minDistance;
  bool enabled;

  GravitySource({
    required this.mass,
    this.minDistance = 1.0,
    this.enabled = true,
  });
}
