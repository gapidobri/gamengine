import 'dart:ui';

import 'package:gamengine/src/ecs/components/component.dart';

abstract class Drawable extends Component {
  int z;
  Paint? paint;

  Drawable({this.z = 0, this.paint});
}
